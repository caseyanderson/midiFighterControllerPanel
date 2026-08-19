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
    var count = numToEnable.clip(0, 16);  // safe range 0–16

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


/* USAGE EXAMPLES

~enableAllTwisterStatus.();    // turns on all 16 Twister status buttons ("KNOB X On")
~disableAllTwisterStatus.();   // turns them all off again

~enableSpectraStatus.(4);     // turn on only first 4 (BUTTON 0–3)
~enableSpectraStatus.(8);     // first 8 (common half-panel)
~enableSpectraStatus.(12);    // first 12
~enableSpectraStatus.(16);    // all of them (same as ~enableSpectraStatus.())
~enableSpectraStatus.(0);     // turn all off (equivalent to ~disableAllSpectraStatus.())

~disableAllSpectraStatus.();  // quick all-off
*/