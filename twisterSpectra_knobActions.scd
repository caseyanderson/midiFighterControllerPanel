// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ KNOB ACTION LOGIC │
// └─────────────────────────────────────────────────────────────────────────────┘
~installTwisterKnobActions = {
    ~knobs.do { |num|
        var strip = ~twisterData[\twisterStrips][num];

        if(strip.notNil, {
            if(strip[\knob].notNil, {
                strip[\knob].action_({ |obj|
                    var val = obj.value;

                    strip[\number2].value_(
                        val.linlin(
                            0,
                            1,
                            strip[\dispMin] ? 0.0,
                            strip[\dispMax] ? 1.0
                        )
                    );

                    if(~twisterStatus[num] == 1, {
                        ~twisterBusses[num].set(val);
                        ~twisterLastBusValue[num] = val;
                        ~synthControl.sendMsg(
                            '/knobControl',
                            num,
                            val
                        );
                    });
                });
            });

            if(strip[\number2].notNil, {
                strip[\number2].action_({ |box|
                    var displayMin;
                    var displayMax;
                    var displayValue;
                    var normalizedValue;

                    displayMin = strip[\dispMin] ? 0.0;
                    displayMax = strip[\dispMax] ? 1.0;

                    if(~twisterStatus[num] == 1, {
                        displayValue =
                        box.value.clip(displayMin, displayMax);

                        normalizedValue =
                        displayValue.linlin(
                            displayMin,
                            displayMax,
                            0,
                            1
                        );

                        strip[\knob]
                        .valueAction_(normalizedValue);

                        box.value_(displayValue);
                    }, {
                        box.value_(
                            strip[\knob].value.linlin(
                                0,
                                1,
                                displayMin,
                                displayMax
                            )
                        );
                    });
                });
            });
        });
    };

    nil;
};

~installTwisterKnobActions.();
