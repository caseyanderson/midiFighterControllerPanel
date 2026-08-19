/*
MIDI Fighter Twister + Spectra Control Panel
Casey Anderson
Twister: CC 0-15, Channel 1 (chan=0)
Spectra: CC 36-51, Channel 4 (chan=3)

On Winddows: connects to Voicemeeter Virtual ASIO
on Mac: connects to Blackhole 16ch

Usage Example (from another file startup block)

~platform = \windows; // or \mac
(~paths[~platform] ++ "twister+spectraControllerPanel.scd").load;

*/

(
// get controller functions file
~paths = (
	mac: "/Users/cta/in_progress_sc/2025/MIDIFighterControllerPanels/",
	windows: "C:/Users/cta/in_progress_sc/2025/MIDIFighterControllerPanels/"
);
~controllerDir = ~paths[~platform];
(~controllerDir ++ "guiControllerFunctions.scd").load;

// configure and start the server per OS
Server.killAll;
s = Server.default;

///////// Server Connection for Mac / Windows

if(~platform == \mac, {
	s.options.device = "BlackHole 16ch";
	s.options.numOutputBusChannels = 16;
});

if(~platform == \windows, {
	s.options.device = "ASIO : Voicemeeter Virtual ASIO";
	s.options.numOutputBusChannels = 8;
});

/////////

s.options.sampleRate = 48000;
s.options.hardwareBufferSize = 512;
s.options.memSize = 65536;
s.boot;
s.waitForBoot({
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ CONSTANTS & STATE │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~synthControl = NetAddr("127.0.0.1", NetAddr.langPort);
    ~knobs = (0..15);
    ~buttons = (0..15);
    ~ccToButton = Dictionary[
        48 -> 0, 49 -> 1, 50 -> 2, 51 -> 3,
        44 -> 4, 45 -> 5, 46 -> 6, 47 -> 7,
        40 -> 8, 41 -> 9, 42 -> 10, 43 -> 11,
        36 -> 12, 37 -> 13, 38 -> 14, 39 -> 15
    ];
    ~twisterLastValue = Array.fill(16, -1);
    ~twisterLastBusValue = Array.fill(16, 0.0);
    ~twisterLastSetTime = Array.fill(16, -999999.0);
    ~spectraLastValue = Array.fill(16, -1);
    ~twisterData = Dictionary.new;
    ~spectraData = Dictionary.new;
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ CONTROL BUSSES │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~twisterBusses = ~knobs.collect { Bus.control(s, 1).set(0.0) };
    ~spectraBusses = ~buttons.collect { Bus.control(s, 1).set(0.0) };
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ GUI LAYOUT HELPERS │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~twisterLayout = { |knobNum|
        var statusButton, knob, knobValDisplay, view;
        statusButton = Button()
            .minSize_(80@30)
            .states_([
                ["KNOB " ++ knobNum ++ " Off", Color.black, Color.gray],
                ["KNOB " ++ knobNum ++ " On", Color.white, Color.red]
            ])
            .value_(0);
        statusButton.action_({ |but|
            if(but.value == 0, { ~twisterBusses[knobNum].set(0.0); });
        });
        knob = Knob().minSize_(80@80).value_(0.0);
        knobValDisplay = NumberBox().minSize_(80@30).align_(\center).value_(0.0).clipLo_(0.0).clipHi_(1.0).decimals_(3);
        view = View().background_(Color.gray(0.9))
            .layout_(VLayout(statusButton, knob, knobValDisplay).spacing_(5).margins_([10,5,10,5]));
        IdentityDictionary[
            \layout -> view,
            \button -> statusButton,
            \knob -> knob,
            \number2 -> knobValDisplay
        ];
    };
    ~spectraLayout = { |buttonNum|
        var statusButton, button, view;
        statusButton = Button()
            .minSize_(80@30)
            .states_([
                ["BUTTON " ++ buttonNum ++ " Off", Color.black, Color.gray],
                ["BUTTON " ++ buttonNum ++ " On", Color.white, Color.red]
            ])
            .value_(0);
        statusButton.action_({ |but|
            if(but.value == 0, { button.valueAction_(0); });
        });
        button = Button()
            .minSize_(80@80)
            .states_([
                ["OFF", Color.black, Color.gray],
                ["ON", Color.white, Color.red]
            ])
            .value_(0);
        view = View().background_(Color.gray(0.9))
            .layout_(VLayout(statusButton, button).spacing_(5).margins_([10,5,10,5]));
        IdentityDictionary[
            \layout -> view,
            \button1 -> statusButton,
            \button2 -> button
        ];
    };
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ GUI CREATION & LAYOUT │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~makeCombinedPanel = {
        var twisterStrips, spectraStrips;
        twisterStrips = ~knobs.collect(~twisterLayout.(_));
        spectraStrips = ~buttons.collect(~spectraLayout.(_));
        if(~combinedPanel.notNil, { ~combinedPanel.close });
        ~twisterData[\twisterStrips] = twisterStrips;
        ~spectraData[\spectraStrips] = spectraStrips;
        ~combinedPanel = Window.new("Twister + Spectra Control Panel", Rect(0,0,892,692))
            .alwaysOnTop_(true)
            .layout_(
                VLayout(
                    HLayout(
                        GridLayout.rows(
                            *twisterStrips.clump(4).collect { |row| row.collect { |strip| strip[\layout] } }
                        ).hSpacing_(10).vSpacing_(10),
                        GridLayout.rows(
                            *spectraStrips.clump(4).collect { |row| row.collect { |strip| strip[\layout] } }
                        ).hSpacing_(10).vSpacing_(10)
                    ).spacing_(10),
                    HLayout(
                        nil,
                        Button()
                            .minSize_(170@34)
                            .states_([
                                ["Knobs All Off", Color.black, Color.gray],
                                ["Knobs All On", Color.white, Color.red]
                            ])
                            .value_(0)
                            .action_({ |but|
                                if(but.value == 1, ~enableAllTwisterStatus, ~disableAllTwisterStatus);
                            }),
                        Button()
                            .minSize_(170@34)
                            .states_([
                                ["Buttons All Off", Color.black, Color.gray],
                                ["Buttons All On", Color.white, Color.red]
                            ])
                            .value_(0)
                            .action_({ |but|
                                if(but.value == 1, { ~enableSpectraStatus.(16) }, ~disableAllSpectraStatus);
                            }),
                        nil
                    ).margins_([5,4,5,6])
                )
            )
            .front;
        ~combinedPanel.bounds_(
            Rect(
                (Window.screenBounds.width - 892) / 2,
                (Window.screenBounds.height - 692) / 2,
                892,
                692
            )
        );
    };
    ~makeCombinedPanel.value;
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ KNOB ACTION LOGIC │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~knobs.do { |num|
        var strip = ~twisterData[\twisterStrips][num];
        if(strip.notNil && strip[\knob].notNil, {
            strip[\knob].action_({ |obj|
                strip[\number2].value_(obj.value);
                if(strip[\button].value == 1, {
                    var val = obj.value;
                    var now = thisThread.seconds;
                    var lastVal = ~twisterLastBusValue[num] ? 0.0;
                    var delta = (val - lastVal).abs;
                    var lastTime = ~twisterLastSetTime[num] ? -999999.0;
                    if(delta > 0.015 && (now - lastTime > 0.02), {
                        var finalVal = val;
                        ~twisterBusses[num].set(finalVal);
                        ~twisterLastBusValue[num] = finalVal;
                        ~twisterLastSetTime[num] = now;
                        ~synthControl.sendMsg('/knobControl', num, finalVal);
                    });
                    if(val < 0.04, {
                        ~twisterBusses[num].set(0.0);
                        ~twisterLastBusValue[num] = 0.0;
                        ~twisterLastSetTime[num] = now;
                    });
                });
            });
        });
    };
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ MIDI CLIENT & RESPONDERS │
    // └─────────────────────────────────────────────────────────────────────────────┘
    MIDIClient.init;
    MIDIIn.connectAll;
    ~twisterUID = MIDIClient.sources.detect { |src| src.name.contains("Twister") }.tryPerform(\uid);
    ~spectraUID = MIDIClient.sources.detect { |src| src.name.contains("Spectra") }.tryPerform(\uid);
    if(~twisterUID.notNil, {
        ~knobs.do { |i|
            MIDIFunc.cc({ |val, cc, chan, src|
                if(chan == 0 && cc == i, {
                    var mappedVal = val.linlin(0,127,0.0,1.0);
                    if(~twisterLastValue[i].isNil || mappedVal != ~twisterLastValue[i], {
                        ~twisterLastValue[i] = mappedVal;
                        {
                            var strip = ~twisterData[\twisterStrips][i];
                            if(strip.notNil && strip[\button].value == 1, {
                                strip[\knob].valueAction_(mappedVal);
                                ~synthControl.sendMsg('/knobControl', i, mappedVal);
                            });
                        }.defer;
                    });
                });
            }, i, 0, ~twisterUID);
        };
        ~toggleTwisterStatus = { |note|
            {
                var strip = ~twisterData[\twisterStrips][note];
                if(strip.notNil && strip[\button].notNil, {
                    strip[\button].valueAction_(1 - strip[\button].value);
                });
            }.defer;
        };
        MIDIFunc.noteOn({ |vel, note, chan, src|
            if(note >= 0 && note <= 15, {
                ~toggleTwisterStatus.(note);
            });
        }, nil, nil, ~twisterUID);
        MIDIFunc.noteOff({ |vel, note, chan, src|
            if(note >= 0 && note <= 15, {
                ~toggleTwisterStatus.(note);
            });
        }, nil, nil, ~twisterUID);
    });
    if(~spectraUID.notNil, {
        MIDIFunc.cc({ |val, cc, chan, src|
            var idx = ~ccToButton[cc];
            if(idx.notNil && chan == 3, {
                var mappedVal = if(val > 0, 1, 0);
                if(~spectraLastValue[idx].isNil || mappedVal != ~spectraLastValue[idx], {
                    ~spectraLastValue[idx] = mappedVal;
                    AppClock.sched(0, {
                        var strip = ~spectraData[\spectraStrips][idx];
                        if(strip.notNil && strip[\button1].value == 1, {
                            strip[\button2].valueAction_(mappedVal);
                            ~synthControl.sendMsg('/buttonControl', idx, mappedVal);
                        });
                    });
                });
            });
        }, nil, 3, ~spectraUID);
    });
    // ┌─────────────────────────────────────────────────────────────────────────────┐
    // │ CLEANUP │
    // └─────────────────────────────────────────────────────────────────────────────┘
    ~combinedPanel.onClose_({
        ~twisterBusses.do(_.free);
        ~spectraBusses.do(_.free);
        MIDIIn.disconnectAll;
    });
});
)