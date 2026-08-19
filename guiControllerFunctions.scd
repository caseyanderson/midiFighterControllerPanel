// Turn ALL Twister GUI status buttons ON (enable message sending for all 16 knobs)
~enableAllTwisterStatus = {
    ~twisterData[\twisterStrips].do { |strip|
        if(strip.notNil && strip[\button].notNil) {
            strip[\button].valueAction_(1);
        };
    };
    "All 16 Twister GUI status buttons → ENABLED (ON)".postln;
};
// Turn ALL Twister GUI status buttons OFF
~disableAllTwisterStatus = {
    ~twisterData[\twisterStrips].do { |strip|
        if(strip.notNil && strip[\button].notNil) {
            strip[\button].valueAction_(0);
        };
    };
    "All 16 Twister GUI status buttons → DISABLED (OFF)".postln;
};
// Turn ON the first N Spectra GUI status buttons (BUTTON X On)
~enableSpectraStatus = { |numToEnable = 8|
    var count = numToEnable.clip(0, 16); // safe range 0–16
    ~spectraData[\spectraStrips].do { |strip, i|
        if(strip.notNil && strip[\button1].notNil) {
            var newVal = if(i < count, 1, 0);
            strip[\button1].valueAction_(newVal);
        };
    };
    "Spectra: first % GUI status buttons → ENABLED (ON), rest OFF".format(count).postln;
};
// Turn ALL Spectra status buttons OFF (convenience)
~disableAllSpectraStatus = {
    ~spectraData[\spectraStrips].do { |strip|
        if(strip.notNil && strip[\button1].notNil) {
            strip[\button1].valueAction_(0);
        };
    };
    "All Spectra GUI status buttons → DISABLED (OFF)".postln;
};
~labelTwisterKnob = { |num, name|
    var strip = ~twisterData[\twisterStrips][num];
    if(strip.notNil && strip[\button].notNil, {
        strip[\label] = name;
        strip[\button].states_([
            [name, Color.black, Color.gray],
            [name, Color.white, Color.red]
        ]);
        strip[\button].refresh;
    });
};
~setTwisterDisplayRange = { |num, min = 0.0, max = 1.0|
    var strip = ~twisterData[\twisterStrips][num];
    if(strip.notNil, {
        strip[\dispMin] = min;
        strip[\dispMax] = max;
        if(strip[\number2].notNil, {
            strip[\number2].value_(
                strip[\knob].value.linlin(0, 1, min, max)
            );
        });
    });
};
~labelTwisterColumn = { |col, name|
    if(~twisterColumnLabels.notNil, {
        ~twisterColumnLabels[col].string_(name);
    });
};
~applyTwisterMap = { |list, col, colName|
    if(col.notNil && colName.notNil, {
        ~labelTwisterColumn.(col, colName);
    });
    list.do { |item|
        ~labelTwisterKnob.(item[\knob], item[\label]);
        ~setTwisterDisplayRange.(item[\knob], item[\min], item[\max]);
    };
};
////////////////////////////////////
/* USAGE EXAMPLES
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();
~enableSpectraStatus.(4);
~enableSpectraStatus.(8);
~enableSpectraStatus.(12);
~enableSpectraStatus.(16);
~enableSpectraStatus.(0);
~disableAllSpectraStatus.();
~labelTwisterColumn.(0, "goopyBubble");
~labelTwisterKnob.(0, "amp");
~labelTwisterKnob.(4, "outGain");
~setTwisterDisplayRange.(4, 0.4, 2.2);

~goopyMap = [
	(knob: 0,  arg: \amp,        label: "amp",     min: 0.0, max: 1.0),
	(knob: 4,  arg: \outGainCtl, label: "outGain", min: 0.4, max: 2.2),
	(knob: 8,  arg: \goopCtl,    label: "goop",    min: 0.3, max: 1.0),
	(knob: 12, arg: \decay,      label: "decay",   min: 0.4, max: 1.4),
];
~applyTwisterMap.(~goopyMap, 0, "goopyBubble");
*/