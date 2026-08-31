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

~spectraDestination = MIDIClient.destinations.detect { |dest|
	dest.name.contains("Spectra")
};

~spectraLEDOut = if(~spectraDestination.notNil, {
	MIDIOut.newByName(
		~spectraDestination.device,
		~spectraDestination.name,
		false
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

                            if(strip.notNil && ~twisterStatus[i] == 1, {
								strip[\knob].valueAction_(mappedVal);
							});
						}.defer;
					});
				});
			}, i, 0, ~twisterUID)
		);
	};

	~setTwisterStatus = { |note, isActive|
		var status = isActive.asInteger;

		if(~controllerPanelMode != \performance, {
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

            if(strip.notNil, {
                if(strip[\button].notNil, {
                    strip[\button].value_(status);
                });
            });

            if(status == 1, {
                var currentValue = ~twisterBusses[note].getSynchronous;

                ~twisterLastBusValue[note] = currentValue;

                if(strip.notNil, {
                    if(strip[\knob].notNil, {
                        strip[\knob].value_(currentValue);
                        strip[\number2].value_(currentValue.linlin(
                            0, 1,
                            strip[\dispMin] ? 0.0,
                            strip[\dispMax] ? 1.0
                        ));
                    });
                });
            });

			}.defer;
		});
		nil;
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
			if(~twisterStatus[note] == 1, {
				~twisterLEDOut.noteOn(1, note, ~twisterActiveLED);
			}, {
				~twisterLEDOut.noteOff(1, note, 0);
			});
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

	~setSpectraButtonActive = { |idx, isActive|
		var active = isActive.asInteger;

		~spectraButtonActive[idx] = active;

		~setSpectraLED.(
			idx,
			if(~spectraStatus[idx] == 1, {
				if(
					active == 1,
					~spectraPressedLED,
					~spectraActiveLED
				)
			}, {
				~spectraInactiveLED
			})
		);

		{
			var strip = ~spectraData[\spectraStrips][idx];

			if(
				strip.notNil
				and: { strip[\button2].notNil },
				{
					strip[\button2].value_(active);
				}
			);
		}.defer;

		nil;
	};

	~completeSpectraButton = { |idx|
		if(
			idx.inclusivelyBetween(0, 15)
			and: { ~spectraDeterministic[idx] },
			{
				~setSpectraButtonActive.(idx, false);
			}
		);

		nil;
	};

	~setSpectraStatus = { |idx, isActive|
		var status = isActive.asInteger;

		if(~controllerPanelMode != \performance, {
			~spectraStatus[idx] = status;
			~setSpectraLED.(
				idx,
				if(status == 1, ~spectraActiveLED, ~spectraInactiveLED)
			);

			{
				var strip = ~spectraData[\spectraStrips][idx];

            if(strip.notNil, {
                if(strip[\button1].notNil, {
                    strip[\button1].value_(status);

                    if(status == 0, {
                        ~spectraToggleValue[idx] = 0;
						~spectraButtonActive[idx] = 0;
                        strip[\button2].valueAction_(0);
                    });
                });
            });

			}.defer;
		});
		nil;
	};

	~spectraCCFunc = MIDIFunc.cc({ |val, cc, chan, src|
		var idx = ~ccToButton[cc];

		if(idx.notNil && chan == 3, {
			var mappedVal = if(val > 0, 1, 0);

			if(~spectraLastValue[idx].isNil || mappedVal != ~spectraLastValue[idx], {
				~spectraLastValue[idx] = mappedVal;

				if(~spectraToggle[idx], {
					if(
						mappedVal == 1
						and: { ~spectraStatus[idx] == 1 },
						{
							~spectraToggleValue[idx] =
							1 - ~spectraToggleValue[idx];

							~setSpectraLED.(
								idx,
								if(
									~spectraToggleValue[idx] == 1,
									~spectraPressedLED,
									~spectraActiveLED
								)
							);

							AppClock.sched(0, {
								var strip =
								~spectraData[\spectraStrips][idx];

								if(strip.notNil, {
									strip[\button2]
									.value_(~spectraToggleValue[idx]);

									~synthControl.sendMsg(
										'/buttonControl',
										idx,
										~spectraToggleValue[idx]
									);
								});
							});
						}
					);

					if(~spectraStatus[idx] == 0, {
						~setSpectraLED.(idx, ~spectraInactiveLED);
					});
				}, {
					if(~spectraDeterministic[idx], {
						if(~spectraStatus[idx] == 1, {
							if(
								mappedVal == 1
								and: { ~spectraButtonActive[idx] == 0 },
								{
									~setSpectraButtonActive.(idx, true);
									~synthControl.sendMsg(
										'/buttonControl',
										idx,
										1
									);
								}
							);

							if(mappedVal == 0, {
								~synthControl.sendMsg(
									'/buttonControl',
									idx,
									0
								);
							});
						}, {
							~setSpectraLED.(idx, ~spectraInactiveLED);
						});
					}, {
						if(~spectraStatus[idx] == 1, {
							~setSpectraLED.(
								idx,
								if(
									mappedVal == 1,
									~spectraPressedLED,
									~spectraActiveLED
								)
							);
						}, {
							~setSpectraLED.(idx, ~spectraInactiveLED);
						});

						AppClock.sched(0, {
							var strip = ~spectraData[\spectraStrips][idx];

							if(
								strip.notNil
								and: { ~spectraStatus[idx] == 1 },
								{
									strip[\button2].valueAction_(mappedVal);
									~synthControl.sendMsg(
										'/buttonControl',
										idx,
										mappedVal
									);
								}
							);
						});
					});
				});
			});
		});
	}, nil, 3, ~spectraUID);

	if(~spectraLEDOut.notNil, {
		~buttons.do { |idx|
			~setSpectraLED.(
				idx,
				if(
					~spectraStatus[idx] == 1,
					~spectraActiveLED,
					~spectraInactiveLED
				)
			);
		};
	});
});
