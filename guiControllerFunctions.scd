// Turn ALL Twister GUI status buttons ON (enable message sending for all 16 knobs)
~enableAllTwisterStatus = {
    ~knobs.do { |knobNum|
        ~setTwisterStatus.(knobNum, true);
    };
    "All 16 Twister GUI status buttons → ENABLED (ON)".postln;
};
// Turn ALL Twister GUI status buttons OFF
~disableAllTwisterStatus = {
    ~knobs.do { |knobNum|
        ~setTwisterStatus.(knobNum, false);
    };
    "All 16 Twister GUI status buttons → DISABLED (OFF)".postln;
};
// Turn ON the first N Spectra GUI status buttons (BUTTON X On)
~enableSpectraStatus = { |numToEnable = 8|
    var count = numToEnable.clip(0, 16);
    ~buttons.do { |buttonNum|
        ~setSpectraStatus.(buttonNum, buttonNum < count);
    };
    "Spectra: first % GUI status buttons → ENABLED (ON), rest OFF".format(count).postln;
};
// Turn ALL Spectra status buttons OFF
~disableAllSpectraStatus = {
    ~buttons.do { |buttonNum|
        ~setSpectraStatus.(buttonNum, false);
    };
    "All Spectra GUI status buttons → DISABLED (OFF)".postln;
};
~labelTwisterKnob = { |num, name|
    var strip = ~twisterData[\twisterStrips].tryPerform(\at, num);
    ~twisterLabels[num] = name;
    if(strip.notNil, {
        if(strip[\button].notNil, {
            if(~controllerPanelMode == \prototype, {
                strip[\button].states_([
                    [name, Color.black, Color.gray],
                    [name, Color.white, Color.red]
                ]);
                strip[\button].value_(~twisterStatus[num]);
            }, {
                strip[\button].string_(name);
            });
            strip[\button].refresh;
        });
    });
};
~setTwisterDisplayRange = { |num, min = 0.0, max = 1.0|
    var strip = ~twisterData[\twisterStrips].tryPerform(\at, num);
    ~twisterDisplayMins[num] = min;
    ~twisterDisplayMaxes[num] = max;
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
    ~twisterColumnNames[col] = name;
    if(~twisterColumnLabels.notNil, {
        ~twisterColumnLabels[col].string_(name);
    });
};
~labelSpectraButton = { |num, name|
    var strip = ~spectraData[\spectraStrips].tryPerform(\at, num);
    ~spectraLabels[num] = name;
    if(strip.notNil, {
        if(strip[\button1].notNil, {
            if(~controllerPanelMode == \prototype, {
                strip[\button1].states_([
                    [name, Color.black, Color.gray],
                    [name, Color.white, Color.red]
                ]);
                strip[\button1].value_(~spectraStatus[num]);
            }, {
                strip[\button1].string_(name);
            });
            strip[\button1].refresh;
        });
    });
};
~applyTwisterMap = { |list, col, colName|
    if(col.notNil && colName.notNil, {
        ~labelTwisterColumn.(col, colName);
        ~labelSpectraButton.(col, colName);
    });
    list.do { |item|
        ~labelTwisterKnob.(item[\knob], item[\label]);
        ~setTwisterDisplayRange.(item[\knob], item[\min], item[\max]);
    };
};
