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