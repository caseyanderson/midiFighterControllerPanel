# midiFighterControllerPanel

SuperCollider tools for the MIDI Fighter Twister + Spectra: GUI, control busses, MIDI/OSC routing, status synchronization, and optional performance layouts

## Requirements

- SuperCollider
- MIDI Fighter Twister
- MIDI Fighter Spectra
- **Windows:** VoiceMeeter Virtual ASIO
- **Mac:** An aggregate device named `BlackHole + MixPre`, with BlackHole 16ch followed by MixPre-3M

## Setup

Clone this repository into your home directory as `midiFighterControllerPanel`, then load it from SuperCollider:

```supercollider
(
~controllerDir = Platform.userHomeDir +/+ "midiFighterControllerPanel";
(~controllerDir +/+ "twister+spectraControllerPanel.scd").load;
)
```

The panel selects Voicemeeter Virtual ASIO on Windows and the `BlackHole + MixPre` aggregate device on macOS

## Controller configuration

Configure the controllers in Midi Fighter Utility:

- **Twister:** Set each encoder switch to **Note Toggle**
- **Spectra:** Enable **Momentary CC**
- **Spectra:** Disable **Spark** under Animations so disabled pads remain visually off when pressed

## Features

- 16 Twister knobs mapped to control busses `~twisterBusses[0..15]` with values from `0.0` to `1.0`
- 16 Spectra pads with GUI control and OSC `/buttonControl` messages
- Active Twister knobs send GUI updates, OSC `/knobControl` messages, and red hardware LED feedback
- Active Spectra pads are red when idle and yellow while held
- GUI controls, physical controls, and enable/disable helpers stay synchronized
- Optional source labels, parameter labels, and scaled number-box ranges through maps
- Prototype and performance modes with Twister-only, Spectra-only, or combined layouts

## Status and LED feedback

Each controller’s status stays synchronized across hardware, GUI, and helper functions

### Twister

- Press an encoder switch, click its GUI status button, or call a Twister status helper to update the same activation state
- Active knobs show red LED feedback and inactive knobs are off
- Only active knobs update the GUI, OSC, and control busses from incoming encoder CC messages
- Disabling a knob resets its control bus to `0.0`

### Spectra

- Click a Spectra GUI status button or call a Spectra helper to update both the GUI and hardware LED
- Disabled pads are off and do not pass their physical press/release state to the panel
- Active pads are red when idle and bright yellow while physically held
- Releasing an active pad returns it to red

To customize Spectra LED colors, change these values in `twisterSpectra_init.scd`:

```supercollider
~spectraInactiveLED = 7;
~spectraActiveLED = 13;
~spectraPressedLED = 37;
```

## Prototype and performance modes

Use prototype mode to expose all available controls, assign maps, and enable or disable controls:

```supercollider
~setControllerPanelMode.(\prototype);
```

Use performance mode to show only active controls. Status labels become static text and controls cannot be activated or deactivated from the performance panel:

```supercollider
~setControllerPanelMode.(\performance);
```

Select which controllers appear in either mode:

```supercollider
~setControllerPanelControllers.(\twister);
~setControllerPanelControllers.(\spectra);
~setControllerPanelControllers.(\both);
```

## Direct performance startup

A project can define its finished controller state before loading the panel. Active controls appear in performance mode and their hardware LEDs initialize to match:

```supercollider
(
~controllerPanelInitialConfig = (
    mode: \performance,
    controllers: \both,
    twisterActive: [0, 4, 8],
    spectraActive: [0]
);

~controllerDir = Platform.userHomeDir +/+ "midiFighterControllerPanel";
(~controllerDir +/+ "twister+spectraControllerPanel.scd").load;
)
```

`twisterActive` and `spectraActive` contain controller indices from `0` through `15`

## Deferred panel opening

Projects that need source maps before the GUI appears can defer panel construction:

```supercollider
(
~controllerDir = Platform.userHomeDir +/+ "midiFighterControllerPanel";

~controllerPanelInitialConfig = (
    mode: \performance,
    controllers: \both,
    twisterActive: [0, 4, 8],
    spectraActive: [0]
);

~controllerPanelDeferOpen = true;
(~controllerDir +/+ "twister+spectraControllerPanel.scd").load;

s.waitForBoot({
    ~sourceMaps = [
        (
            name: \exampleSource,
            map: [
                (knob: 0, arg: \amp, label: "amp", min: 0.0, max: 1.0),
                (knob: 4, arg: \rate, label: "rate", min: 0.1, max: 12.0),
                (knob: 8, arg: \depth, label: "depth", min: 0.0, max: 1.0)
            ]
        )
    ];

    ~sourceMaps.do { |source, sourceIndex|
        ~applyTwisterMap.(
            source[\map],
            sourceIndex,
            source[\name].asString
        );
    };

    ~openControllerPanel.();
});
)
```

This is useful when a project starts directly in performance mode and needs mapped source labels before the panel is built

## Repo layout

Loading `twister+spectraControllerPanel.scd` loads:

- `guiControllerFunctions.scd` — enable/disable helpers, labels, and `~applyTwisterMap`
- `twisterSpectra_init.scd` — constants, state, control busses, LED colors, and panel configuration
- `twisterSpectra_layouts.scd` — Twister and Spectra strip layouts
- `twisterSpectra_panel.scd` — window assembly and prototype/performance layouts
- `twisterSpectra_knobActions.scd` — GUI knob behavior
- `twisterSpectra_midi.scd` — MIDI responders and hardware LED feedback

## Maps and labels

Use one map entry per source. The source index determines its Twister column and corresponding Spectra label:

```supercollider
(
~sourceMaps = [
    (
        name: \exampleSource,
        map: [
            (knob: 0, arg: \amp, label: "amp", min: 0.0, max: 1.0),
            (knob: 4, arg: \rate, label: "rate", min: 0.1, max: 12.0),
            (knob: 8, arg: \depth, label: "depth", min: 0.0, max: 1.0)
        ]
    )
];

~sourceMaps.do { |source, sourceIndex|
    ~applyTwisterMap.(
        source[\map],
        sourceIndex,
        source[\name].asString
    );
};
)
```

Several source entries use separate Twister columns:

- Source `0` uses knobs `0`, `4`, `8`, and `12`
- Source `1` uses knobs `1`, `5`, `9`, and `13`
- Source `2` uses knobs `2`, `6`, `10`, and `14`
- Source `3` uses knobs `3`, `7`, `11`, and `15`

## Helpers

```supercollider
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();

~enableSpectraStatus.(8);
~disableAllSpectraStatus.();

~applyTwisterMap.(list, sourceIndex, sourceName);

~labelTwisterColumn.(sourceIndex, "name");
~labelTwisterKnob.(knobIndex, "name");
~setTwisterDisplayRange.(knobIndex, min, max);
```

## Notes

- Control-bus values always use the normalized range `0.0` to `1.0`
- A map’s `min` and `max` change only the range shown in the GUI number box and do not rescale the bus value
- `name` should match the SynthDef symbol when triggering a source with `Synth(~sourceMaps[index][\name], ...)`
- Use source names that fit comfortably in the column-label and Spectra status-label areas
