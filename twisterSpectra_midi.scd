// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ MIDI CLIENT & RESPONDERS │
// └─────────────────────────────────────────────────────────────────────────────┘
MIDIClient.init;
MIDIIn.connectAll;

~twisterUID = MIDIClient.sources.detect { |src| src.name.contains("Twister") }.tryPerform(\uid);
~spectraUID = MIDIClient.sources.detect { |src| src.name.contains("Spectra") }.tryPerform(\uid);

~twisterDestination = MIDIClient.destinations.detect { |dest|
	dest.name.contains("Twister")
};

~twisterLEDOut = if(~twisterDestination.notNil, {
	MIDIOut.newByName(
		~twisterDestination.device,
		~twisterDestination.name,
		false
	);
}, {
	"MIDI Fighter Twister output not found; LED feedback is disabled.".warn;
	nil;
});

~spectraDestinationIndex = MIDIClient.destinations.detectIndex { |dest|
	dest.name.contains("Spectra")
};

~spectraLEDOut = if(~spectraDestinationIndex.notNil, {
	MIDIOut(
		~spectraDestinationIndex,
		MIDIClient.destinations[~spectraDestinationIndex].uid
	);
}, {
	"MIDI Fighter Spectra output not found; LED feedback is disabled.".warn;
	nil;
});

// free previous panel responders only
~twisterCCFuncs.do(_.free);
~twisterNoteOnFunc.free;
~twisterNoteOffFunc.free;
~spectraCCFunc.free;
~twisterCCFuncs = List[];

if(~twisterUID.notNil, {
	~knobs.do { |i|
		~twisterCCFuncs.add(
			MIDIFunc.cc({ |val, cc, chan, src|
				if(chan == 0 && cc == i, {
					var mappedVal = val.linlin(0, 127, 0.0, 1.0);

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
			}, i, 0, ~twisterUID)
		);
	};

	~setTwisterStatus = { |note, isActive|
		var status = isActive.asInteger;

		~twisterStatus[note] = status;

		if(~twisterLEDOut.notNil, {
			if(status == 1, {
				~twisterLEDOut.noteOn(1, note, ~twisterActiveLED);
			}, {
				~twisterLEDOut.noteOff(1, note, 0);
			});
		});

		{
			var strip = ~twisterData[\twisterStrips][note];

			if(strip.notNil && strip[\button].notNil, {
				strip[\button].value_(status);
			});

			if(status == 0, {
				~twisterBusses[note].set(0.0);
			});
		}.defer;
	};

	~twisterNoteOnFunc = MIDIFunc.noteOn({ |vel, note, chan, src|
		if(note >= 0 && note <= 15, {
			~setTwisterStatus.(note, vel > 0);
		});
	}, nil, nil, ~twisterUID);

	~twisterNoteOffFunc = MIDIFunc.noteOff({ |vel, note, chan, src|
		if(note >= 0 && note <= 15, {
			~setTwisterStatus.(note, false);
		});
	}, nil, nil, ~twisterUID);

	if(~twisterLEDOut.notNil, {
		~knobs.do { |note|
			~twisterLEDOut.noteOff(1, note, 0);
		};
	});
});

if(~spectraUID.notNil, {
	~setSpectraLED = { |idx, color|
		var midiNumber = ~ccToButton.keys.detect { |cc|
			~ccToButton[cc] == idx
		};

		if(~spectraLEDOut.notNil && midiNumber.notNil, {
			~spectraLEDOut.noteOn(2, midiNumber, color);
		});
	};

	~setSpectraStatus = { |idx, isActive|
		var status = isActive.asInteger;

		~spectraStatus[idx] = status;
		~setSpectraLED.(
			idx,
			if(status == 1, ~spectraActiveLED, ~spectraInactiveLED)
		);

		{
			var strip = ~spectraData[\spectraStrips][idx];

			if(strip.notNil && strip[\button1].notNil, {
				strip[\button1].value_(status);

				if(status == 0, {
					strip[\button2].valueAction_(0);
				});
			});
		}.defer;
	};

	~spectraCCFunc = MIDIFunc.cc({ |val, cc, chan, src|
		var idx = ~ccToButton[cc];

		if(idx.notNil && chan == 3, {
			var mappedVal = if(val > 0, 1, 0);

			if(~spectraLastValue[idx].isNil || mappedVal != ~spectraLastValue[idx], {
				~spectraLastValue[idx] = mappedVal;

				if(~spectraStatus[idx] == 1, {
					~setSpectraLED.(
						idx,
						if(mappedVal == 1, ~spectraPressedLED, ~spectraActiveLED)
					);
				}, {
					~setSpectraLED.(idx, ~spectraInactiveLED);
				});

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

	if(~spectraLEDOut.notNil, {
		~buttons.do { |idx|
			~setSpectraLED.(idx, ~spectraInactiveLED);
		};
	});
});
