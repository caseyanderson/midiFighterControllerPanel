# midiFighterControllerPanel

SuperCollider tools for the MIDI Fighter Twister + Spectra: GUI, control busses, and MIDI/OSC routing for prototyping and performance.

## Requirements

- SuperCollider
- MIDI Fighter Twister (CC 0–15, channel 1)
- MIDI Fighter Spectra (CC 36–51, channel 4)
- **Windows:** VoiceMeeter (Banana) Virtual ASIO
- **Mac:** BlackHole 16ch

## Setup

1. Clone this repo (or place the files) in the same path on each machine, or update the paths below.
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
- Status buttons enable/disable each control (gray = off, red = on)
- Optional labels and display ranges (see below)

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
// Map synth args to ~twisterBusses[n].asMap as needed
)

// Wait for the GUI window to load, then:
(
///////// LABELS (optional)
~labelTwisterColumn.(0, "synthName");
~labelTwisterKnob.(0, "paramA");
~labelTwisterKnob.(4, "paramB");
~setTwisterDisplayRange.(4, 0.0, 1.0); // min/max for number box only; bus stays 0–1
)

(
///////// OSC / control
// Listen to '/buttonControl' or '/knobControl' as needed
// Example: enable a knob's bus with .asMap when creating Synths
)
```

## Helpers

```supercollider
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();
~enableSpectraStatus.(8);   // first N status buttons on
~disableAllSpectraStatus.();

~labelTwisterColumn.(col, "name");     // col 0–3
~labelTwisterKnob.(num, "name");       // num 0–15
~setTwisterDisplayRange.(num, min, max);
```

## Notes

- Twister knobs are often grouped by column: `0,4,8,12` / `1,5,9,13` / etc.
- Busses always carry 0–1. Display ranges only affect the number boxes.
- Press a Twister encoder (Note Toggle) or click its status button to enable/disable that knob.
- Encoder switches must be set to **Note Toggle** in Midi Fighter Utility.

