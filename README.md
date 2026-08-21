# midiFighterControllerPanel

SuperCollider tools for the MIDI Fighter Twister + Spectra: GUI, control busses, and MIDI/OSC routing for prototyping and performance.

## Requirements

- SuperCollider
- MIDI Fighter Twister (CC 0–15, channel 1)
- MIDI Fighter Spectra (CC 36–51, channel 4)
- **Windows:** VoiceMeeter (Banana) Virtual ASIO
- **Mac:** BlackHole 16ch

## Setup

1. Clone this repository, then set the path for your machine below.
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

3. Wait until the control panel window appears before running further blocks.

## Controller configuration

Configure the controllers in Midi Fighter Utility:

- **Twister:** Set each encoder switch to **Note Toggle**. The panel uses those note messages to enable and disable each knob.
- **Spectra:** Enable **Momentary CC**. The panel receives press/release CC messages on channel 4.
- **Spectra:** Disable **Spark** under Animations. This keeps disabled pads visually off when pressed.

## Features

- 16 Twister knobs → control busses `~twisterBusses[0..15]` (values 0.0–1.0)
- 16 Spectra pads → GUI control and OSC `/buttonControl` messages
- Active Twister knobs → GUI control, OSC `/knobControl` messages, and red LEDs on the hardware
- Active Spectra pads → red when idle and yellow while held; disabled pads remain off
- GUI controls, physical controls, and enable/disable helpers stay in sync
- Optional column/knob labels and scaled number-box ranges via maps (see below)

## Status and LED feedback

Each controller’s status is synced across the hardware, GUI, and helper functions.

### Twister

- Pressing an encoder switch, clicking its GUI status button, or calling a Twister status helper updates the same state.
- Active knobs show red LED feedback; inactive knobs are off.
- Only active knobs update the GUI, OSC, and control busses from incoming encoder CC messages.
- Disabling a knob resets its control bus to `0.0`.

### Spectra

- Clicking a Spectra GUI status button or calling a Spectra helper updates both the GUI and hardware LED.
- Disabled pads are off and do not pass their physical press/release state to the panel.
- Active pads are red when idle and bright yellow while physically held.
- Releasing an active pad returns it to red.

To customize the Spectra LED colors, change these values in `twisterSpectra_init.scd`:

```supercollider
~spectraInactiveLED = 7;
~spectraActiveLED = 13;
~spectraPressedLED = 37;
```

## Repo layout

Loading `twister+spectraControllerPanel.scd` loads:

- `guiControllerFunctions.scd` — enable/disable helpers, labels, `~applyTwisterMap`
- `twisterSpectra_init.scd` — constants, state, control busses, and LED color values
- `twisterSpectra_layouts.scd` — Twister and Spectra strip layouts
- `twisterSpectra_panel.scd` — window assembly
- `twisterSpectra_knobActions.scd` — GUI knob behavior
- `twisterSpectra_midi.scd` — MIDI responders and hardware LED feedback

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
- Control-bus values use a normalized range of `0.0` to `1.0`. A map’s `min` and `max` only change the range shown in the GUI number box; they do not rescale the bus value.
- Preferred labeling pattern: use a single map list containing `(name:, map:)` entries, then apply it with `~applyTwisterMap` in a `.do`.
- `name` should match the SynthDef symbol if you create synths with `Synth(~myMaps[n][\name], ...)`.
- Press a Twister encoder (Note Toggle), click its status button, or use the helper functions to enable/disable it.

