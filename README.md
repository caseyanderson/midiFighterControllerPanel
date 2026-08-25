# midiFighterControllerPanel

SuperCollider control panels for the MIDI Fighter Twister and Spectra, with synchronized hardware, GUI, control-bus, and OSC state.

## Requirements

- [SuperCollider](https://supercollider.github.io/): tested with version 3.13.0
- MIDI Fighter Twister, MIDI Fighter Spectra, or both
- Windows: Voicemeeter Virtual ASIO
- macOS: an aggregate device named `BlackHole + MixPre`, with BlackHole 16ch followed by MixPre-3M

## Related repositories

- [projectTemplate](https://github.com/caseyanderson/projectTemplate): reusable project structure and startup workflow
- [gainStageDoctor](https://github.com/caseyanderson/gainStageDoctor): optional source gain, output trim, and metering
- [reaperSessionBridge](https://github.com/caseyanderson/reaperSessionBridge): cross-platform REAPER recording-track synchronization

## Project files

- `twister+spectraControllerPanel.scd`: startup file
- `guiControllerFunctions.scd`: activation, labeling, display-range, and mapping helpers
- `twisterSpectra_init.scd`: controller state, control buses, LED colors, and panel configuration
- `twisterSpectra_layouts.scd`: Twister and Spectra control layouts
- `twisterSpectra_panel.scd`: prototype and performance window assembly
- `twisterSpectra_knobActions.scd`: GUI knob behavior
- `twisterSpectra_midi.scd`: MIDI responders and hardware LED feedback

## Set up the controllers

1. Clone this repository to:

   ```text
   ~/midiFighterControllerPanel
   ```

2. In MIDI Fighter Utility, configure each Twister encoder switch as **Note Toggle**
3. In MIDI Fighter Utility, enable **Momentary CC** for the Spectra
4. Disable **Spark** under Spectra animations so disabled pads remain visually off when pressed
5. Connect the controller hardware
6. Load the panel from SuperCollider:

   ```supercollider
   ~controllerDir =
       Platform.userHomeDir +/+ "midiFighterControllerPanel";

   (~controllerDir
       +/+ "twister+spectraControllerPanel.scd").load;
   ```

The startup file selects Voicemeeter Virtual ASIO on Windows and the `BlackHole + MixPre` aggregate device on macOS.

## Prototype a controller layout

Set the initial mode and choose which controllers appear before loading the panel:

```supercollider
~controllerPanelInitialConfig = (
    mode: \prototype,
    controllers: \both,
    twisterActive: [],
    spectraActive: []
);
```

`controllers` may be `\twister`, `\spectra`, or `\both`.

In prototype mode, use each control's GUI status button to activate or deactivate it. Physical knob turns and button presses pass through only while that control is active.

Apply source labels and Twister mappings after the controller files have loaded:

```supercollider
~sourceMaps = [
    (
        name: \exampleSource,
        map: [
            (
                knob: 0,
                arg: \amp,
                label: "amp",
                min: 0.0,
                max: 1.0
            ),
            (
                knob: 4,
                arg: \rate,
                label: "rate",
                min: 0.1,
                max: 12.0
            )
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
```

The source index determines its Twister column and corresponding Spectra label:

- Source `0`: knobs `0`, `4`, `8`, and `12`
- Source `1`: knobs `1`, `5`, `9`, and `13`
- Source `2`: knobs `2`, `6`, `10`, and `14`
- Source `3`: knobs `3`, `7`, `11`, and `15`

Switch a running panel to prototype mode with:

```supercollider
~setControllerPanelMode.(\prototype);
```

Change the visible controllers with:

```supercollider
~setControllerPanelControllers.(\twister);
~setControllerPanelControllers.(\spectra);
~setControllerPanelControllers.(\both);
```

## Prepare a performance

List only the controls used by the finished project and set the initial mode to `\performance`:

```supercollider
~controllerPanelInitialConfig = (
    mode: \performance,
    controllers: \both,
    twisterActive: [0, 4, 8],
    spectraActive: [0]
);
```

`twisterActive` and `spectraActive` use controller indices from `0` through `15`.

Performance mode shows only the active controls and prevents activation changes from the performance panel.

Switch a running panel to performance mode with:

```supercollider
~setControllerPanelMode.(\performance);
```

### Defer panel opening

Defer panel construction when a project must load its source maps before building the performance interface:

```supercollider
~controllerPanelInitialConfig = (
    mode: \performance,
    controllers: \both,
    twisterActive: [0, 4, 8],
    spectraActive: [0]
);

~controllerPanelDeferOpen = true;

(~controllerDir
    +/+ "twister+spectraControllerPanel.scd").load;

s.waitForBoot({
    ~sourceMaps.do { |source, sourceIndex|
        ~applyTwisterMap.(
            source[\map],
            sourceIndex,
            source[\name].asString
        );
    };

    ~openControllerPanel.();
});
```

## Configuration reference

### Activation helpers

```supercollider
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();

~enableSpectraStatus.(8);
~disableAllSpectraStatus.();
```

### Mapping and label helpers

```supercollider
~applyTwisterMap.(list, sourceIndex, sourceName);

~labelTwisterColumn.(sourceIndex, "name");
~labelTwisterKnob.(knobIndex, "name");
~setTwisterDisplayRange.(knobIndex, min, max);
```

### Spectra LED colors

Set the Spectra LED values in `twisterSpectra_init.scd`:

```supercollider
~spectraInactiveLED = 7;
~spectraActiveLED = 13;
~spectraPressedLED = 37;
```

## Notes

- Twister control buses use normalized values from `0.0` to `1.0`
- Map `min` and `max` values change the GUI number-box display range without rescaling the control bus
- Active Twister controls send GUI updates, OSC `/knobControl` messages, and red hardware LED feedback
- Active Spectra controls send OSC `/buttonControl` messages, appear red while idle, and appear yellow while held
- Use source names that fit comfortably in the column-label and Spectra-label areas
