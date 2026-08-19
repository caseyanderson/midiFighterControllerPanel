# midiFighterControllerPanel

SuperCollider tools for the MIDI Fighter Twister + Spectra: GUI, control busses, and MIDI/OSC routing for prototyping and performance.

## Requirements

- SuperCollider
- MIDI Fighter Twister (CC 0–15, channel 1)
- MIDI Fighter Spectra (CC 36–51, channel 4)
- **Windows:** VoiceMeeter (Banana) Virtual ASIO
- **Mac:** BlackHole 16ch

## Setup

1. Clone this repo (or place the files) in the same path on each machine, or update the paths below
2. In a SuperCollider file, set the platform and load the panel:

```supercollider
(
~platform = \windows; // or \mac
~paths = (
	mac: "/Users/USERNAME/midiFighterControllerPanel/",
	windows: "C:/Users/USERNAME/midiFighterControllerPanel/"
);
~controllerDir = ~paths[~platform];
(~controllerDir ++ "twister+spectraControllerPanel.scd").load;
)
```

3. Wait until the control panel window appears before running further blocks

## What you get

- 16 Twister knobs → control busses `~twisterBusses[0..15]` (values 0.0 – 1.0)
- 16 Spectra buttons → GUI + OSC on `/buttonControl`
- Knob moves can also send `/knobControl`
- Status buttons enable/disable each control (gray = off, red = on)
- Optional column/knob labels and scaled number-box ranges via maps (see below)

## Repo layout

Loading `twister+spectraControllerPanel.scd` pulls in:

- `guiControllerFunctions.scd` — enable/disable helpers, labels, `~applyTwisterMap`
- `twisterSpectra_init.scd` — constants, state, control busses
- `twisterSpectra_layouts.scd` — strip layouts
- `twisterSpectra_panel.scd` — window assembly
- `twisterSpectra_knobActions.scd` — GUI knob behavior
- `twisterSpectra_midi.scd` — MIDI responders

## Typical synth file structure

```supercollider
(
///////// SETUP
~platform = \windows; // or \mac
~paths = (
	mac: "/Users/USERNAME/midiFighterControllerPanel/",
	windows: "C:/Users/USERNAME/midiFighterControllerPanel/"
);
~controllerDir = ~paths[~platform];
(~controllerDir ++ "twister+spectraControllerPanel.scd").load;
// ... any other setup ...
)

(
///////// SYNTHDEF
// Def name should match the symbol used in the maps list below
)

// Wait for the GUI window to load, then:
(
///////// MAP + LABELS
~myMaps = [
	(
		name: \mySynth,
		map: [
			(knob: 0, arg: \amp, label: "amp", min: 0.0, max: 1.0),
			(knob: 4, arg: \outGainCtl, label: "outGain", min: 0.4, max: 2.2),
		]
	),
];
~myMaps.do { |item, i|
	~applyTwisterMap.(item[\map], i, item[\name].asString);
};
)

(
///////// OSC / MIDI
// Synth(~myMaps[0][\name], [
//     \amp, ~twisterBusses[0].asMap,
//     \outGainCtl, ~twisterBusses[4].asMap,
// ]);
)
```

### Several synths (one per Twister column)

Use several `(name:, map:)` entries in the same list. The `.do` index is the column (`0` → knobs `0,4,8,12`, `1` → `1,5,9,13`, etc.):

```supercollider
~myMaps.do { |item, i|
	~applyTwisterMap.(item[\map], i, item[\name].asString);
};
// Synth(~myMaps[idx][\name], ...) when triggering by column/button index
```

## Helpers

```supercollider
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();
~enableSpectraStatus.(8);   // first N Spectra status buttons on
~disableAllSpectraStatus.();

~applyTwisterMap.(list, col, colName); // preferred: labels + display ranges for one column

// Lower-level (used inside ~applyTwisterMap; available if needed):
~labelTwisterColumn.(col, "name");     // col 0–3
~labelTwisterKnob.(num, "name");       // num 0–15
~setTwisterDisplayRange.(num, min, max);
```

## Notes

- Twister knobs are often grouped by column: `0,4,8,12` / `1,5,9,13` / `2,6,10,14` / `3,7,11,15`.
- Busses always carry 0–1. Display `min`/`max` in a map only affect the number boxes.
- Preferred labeling pattern: one maps list of `(name:, map:)` entries; apply with `~applyTwisterMap` in a `.do`.
- `name` should match the SynthDef symbol if you create synths with `Synth(~myMaps[n][\name], ...)`.
- Press a Twister encoder (Note Toggle) or click its status button to enable/disable that knob.
- Encoder switches must be set to **Note Toggle** in Midi Fighter Utility.

