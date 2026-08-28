/*
MIDI Fighter Twister + Spectra Control Panel
Casey Anderson
*/

(
~platform = Platform.case(
	\windows, { \windows },
	\osx, { \mac }
);

~homeDir = Platform.userHomeDir;
~controllerDir = ~homeDir +/+ "midiFighterControllerPanel";
(~controllerDir +/+ "guiControllerFunctions.scd").load;

Server.killAll;
s = Server.default;

///////// Server Connection for Mac / Windows

~serverConfig = (
	mac: (device: "BlackHole + MixPre", numOutputBusChannels: 16),
	windows: (device: "ASIO : Voicemeeter Virtual ASIO", numOutputBusChannels: 8)
)[~platform];

s.options.device = ~serverConfig[\device];
s.options.numOutputBusChannels = ~serverConfig[\numOutputBusChannels];

/////////

s.options.sampleRate = 48000;
s.options.hardwareBufferSize = 512;
s.options.memSize = 65536;
s.boot;

s.waitForBoot({
	(~controllerDir +/+ "twisterSpectra_init.scd").load;
	(~controllerDir +/+ "twisterSpectra_layouts.scd").load;
	(~controllerDir +/+ "twisterSpectra_panel.scd").load;

	~controllerPanelCleanup = {
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
	};

	~openControllerPanel = {
		~controllerPanelIsDeferred = false;
		~makeCombinedPanel.value;
		(~controllerDir +/+ "twisterSpectra_knobActions.scd").load;
		(~controllerDir +/+ "twisterSpectra_midi.scd").load;
		~combinedPanel.onClose_(~controllerPanelCleanup);
	};

	if(~controllerPanelIsDeferred.not, {
		~openControllerPanel.();
	});
});
)
