/*
MIDI Fighter Twister + Spectra Control Panel
Casey Anderson

Twister: CC 0-15, Channel 1 (chan=0)
Spectra: CC 36-51, Channel 4 (chan=3)

On Windows: connects to Voicemeeter Virtual ASIO
on Mac: connects to Blackhole 16ch

Usage Example (from another file startup block)
~platform = \windows; // or \mac
(~paths[~platform] ++ "twister+spectraControllerPanel.scd").load;

*/

(
~paths = (
	mac: "/Users/casey.anderson/midiFighterControllerPanel/",
	windows: "C:/Users/cta/midiFighterControllerPanel/"
);
~controllerDir = ~paths[~platform];
(~controllerDir ++ "guiControllerFunctions.scd").load;

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
	(~controllerDir ++ "twisterSpectra_init.scd").load;
	(~controllerDir ++ "twisterSpectra_layouts.scd").load;
	(~controllerDir ++ "twisterSpectra_panel.scd").load;
	~makeCombinedPanel.value;
	(~controllerDir ++ "twisterSpectra_knobActions.scd").load;
	(~controllerDir ++ "twisterSpectra_midi.scd").load;

~combinedPanel.onClose_({
	s.freeAll;

	~kbSampleOn.free;
	~kbSampleOff.free;
	~kbSampleNotes = Array.newClear(128);

	~twisterCCFuncs.do(_.free);
	~twisterNoteOnFunc.free;
	~twisterNoteOffFunc.free;
	~spectraCCFunc.free;

	~twisterBusses.do(_.free);
	~spectraBusses.do(_.free);
	MIDIIn.disconnectAll;
});
});
)