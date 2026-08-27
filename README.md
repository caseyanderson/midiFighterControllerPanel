# midiFighterControllerPanel

SuperCollider control panels for the MIDI Fighter Twister and Spectra, with synchronized hardware, GUI, control-bus, and OSC state.

midiFighterControllerPanel is designed to work with [projectTemplate](https://github.com/caseyanderson/projectTemplate), [gainStageDoctor](https://github.com/caseyanderson/gainStageDoctor), and [reaperSessionBridge](https://github.com/caseyanderson/reaperSessionBridge).

See the [projectTemplate README](https://github.com/caseyanderson/projectTemplate#readme) for the complete installation, prototyping, performance, and recording workflow.

## Requirements

- [SuperCollider](https://supercollider.github.io/): tested with version 3.13.0
- MIDI Fighter Twister, MIDI Fighter Spectra, or both
- Windows: Voicemeeter Virtual ASIO
- macOS: an aggregate device named `BlackHole + MixPre`

## Files

- `twister+spectraControllerPanel.scd`: startup file
- `guiControllerFunctions.scd`: activation, labeling, display-range, and mapping helpers
- `twisterSpectra_init.scd`: controller state, control buses, LED colors, and panel configuration
- `twisterSpectra_layouts.scd`: Twister and Spectra control layouts
- `twisterSpectra_panel.scd`: prototype and performance window assembly
- `twisterSpectra_knobActions.scd`: GUI knob behavior
- `twisterSpectra_midi.scd`: MIDI responders and hardware LED feedback

## Configure the controller hardware

In MIDI Fighter Utility:

1. Configure each Twister encoder switch as **Note Toggle**
2. Enable **Momentary CC** for the Spectra
3. Disable **Spark** under Spectra animations

Connect the controllers before loading the panel.

## Load the panel directly

For a direct standalone test, evaluate this block in a SuperCollider document before loading `twister+spectraControllerPanel.scd`. In a project based on projectTemplate, define `~controllerPanelInitialConfig` in `project_config.scd`.

```supercollider
~controllerPanelInitialConfig = (
    mode: \prototype,
    controllers: \both,
    twisterActive: [],
    spectraActive: [],
    spectraToggle: [],
    spectraDeterministic: []
);

~controllerDir =
    Platform.userHomeDir +/+ "midiFighterControllerPanel";

(~controllerDir
    +/+ "twister+spectraControllerPanel.scd").load;
```

`controllers` may be:

- `\twister`
- `\spectra`
- `\both`

The startup file selects `Voicemeeter Virtual ASIO` on Windows and the `BlackHole + MixPre` aggregate device on macOS.

## Prototype mode

Prototype mode displays all controls and allows their activation state to be changed.

Physical knob turns and button presses pass through only while the corresponding GUI control is active.

Switch a running panel to prototype mode:

```supercollider
~setControllerPanelMode.(\prototype);
```

Change the visible controllers:

```supercollider
~setControllerPanelControllers.(\twister);
~setControllerPanelControllers.(\spectra);
~setControllerPanelControllers.(\both);
```

## Performance mode

Performance mode displays only the configured active controls and prevents activation changes from the performance interface.

In the consuming project's configuration file, such as projectTemplate's `project_config.scd`, configure the initial performance state before loading the panel:

```supercollider
~controllerPanelInitialConfig = (
    mode: \performance,
    controllers: \both,
    twisterActive: [0, 1],
    spectraActive: [0, 1],
    spectraToggle: [],
    spectraDeterministic: [1]
);
```

`twisterActive` and `spectraActive` use indices from `0` through `15`.

`spectraToggle` lists buttons that alternate between explicit `1` and `0`
states on successive presses. The GUI and hardware LED remain active while
the stored state is `1`.

`spectraDeterministic` lists active Spectra buttons whose state remains active until completion is reported.

Switch a running panel to performance mode:

```supercollider
~setControllerPanelMode.(\performance);
```

## Apply Twister mappings

In projectTemplate, edit each source's `twisterMap` in `project_init.scd`; `project_maps.scd` applies those mappings. The following snippets show the controller helper interface directly.

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
```

Apply the maps after the controller files have loaded:

```supercollider
~sourceMaps.do { |source, sourceIndex|
    ~applyTwisterMap.(
        source[\map],
        sourceIndex,
        source[\name].asString
    );
};
```

The source index determines its controller column:

| Source index | Twister knobs | Spectra label |
|---:|---|---:|
| 0 | 0, 4, 8, 12 | 0 |
| 1 | 1, 5, 9, 13 | 1 |
| 2 | 2, 6, 10, 14 | 2 |
| 3 | 3, 7, 11, 15 | 3 |

Twister control buses contain normalized values from `0.0` to `1.0`. Mapping `min` and `max` values change the GUI number-box display range without rescaling the control bus.

## Activation helpers

```supercollider
~enableAllTwisterStatus.();
~disableAllTwisterStatus.();

~enableSpectraStatus.(8);
~disableAllSpectraStatus.();

~completeSpectraButton.(1);
```

Call `~completeSpectraButton` from the project action or process-completion file, such as projectTemplate's `project_actions.scd`, when the work associated with a deterministic Spectra button has completed.

## Mapping and label helpers

Call these helpers from the project's controller-map file, such as projectTemplate's `project_maps.scd`.

```supercollider
~applyTwisterMap.(list, sourceIndex, sourceName);

~labelTwisterColumn.(sourceIndex, "name");
~labelTwisterKnob.(knobIndex, "name");
~setTwisterDisplayRange.(knobIndex, min, max);
```

## Spectra LED configuration

Set the Spectra LED values in `twisterSpectra_init.scd`:

```supercollider
~spectraInactiveLED = 7;
~spectraActiveLED = 13;
~spectraPressedLED = 37;
```

Active Spectra controls appear red while idle and yellow while active.

## Verify the panel

1. Connect the configured controllers
2. Load `twister+spectraControllerPanel.scd`
3. Activate a Twister control in prototype mode
4. Turn its physical encoder and confirm that the GUI and control bus respond
5. Activate a Spectra control
6. Press its physical pad and confirm that the GUI, OSC state, and hardware LED respond
7. Switch between prototype and performance modes
8. Confirm that performance mode displays only the configured active controls

## Notes

- Active Twister controls send GUI updates, OSC `/knobControl` messages, and hardware LED feedback
- Active Spectra controls send OSC `/buttonControl` messages and hardware LED feedback
- Use source names that fit comfortably in the controller labels
