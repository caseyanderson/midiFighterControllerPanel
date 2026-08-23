// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ KNOB ACTION LOGIC │
// └─────────────────────────────────────────────────────────────────────────────┘
~installTwisterKnobActions = {
    ~knobs.do { |num|
        var strip = ~twisterData[\twisterStrips][num];

        if(strip.notNil, {
            if(strip[\knob].notNil, {
                strip[\knob].action_({ |obj|
                strip[\number2].value_(
                    obj.value.linlin(
                        0, 1,
                        strip[\dispMin] ? 0.0,
                        strip[\dispMax] ? 1.0
                    )
                );

                if(~twisterStatus[num] == 1, {
                    var val = obj.value;
                    var now = thisThread.seconds;
                    var lastVal = ~twisterLastBusValue[num] ? 0.0;
                    var delta = (val - lastVal).abs;
                    var lastTime = ~twisterLastSetTime[num] ? -999999.0;

                    if(delta > 0.015 && (now - lastTime > 0.02), {
                        ~twisterBusses[num].set(val);
                        ~twisterLastBusValue[num] = val;
                        ~twisterLastSetTime[num] = now;
                        ~synthControl.sendMsg('/knobControl', num, val);
                    });

                    if(val < 0.04, {
                        ~twisterBusses[num].set(0.0);
                        ~twisterLastBusValue[num] = 0.0;
                        ~twisterLastSetTime[num] = now;
                    });
                });
                });
            });
        });
    };

    nil;
};

~installTwisterKnobActions.();
