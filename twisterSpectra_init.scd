// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ CONSTANTS & STATE │
// └─────────────────────────────────────────────────────────────────────────────┘
~synthControl = NetAddr("127.0.0.1", NetAddr.langPort);
~knobs = (0..15);
~buttons = (0..15);
~ccToButton = Dictionary[
	48 -> 0, 49 -> 1, 50 -> 2, 51 -> 3,
	44 -> 4, 45 -> 5, 46 -> 6, 47 -> 7,
	40 -> 8, 41 -> 9, 42 -> 10, 43 -> 11,
	36 -> 12, 37 -> 13, 38 -> 14, 39 -> 15
];
~twisterLastValue = Array.fill(16, -1);
~twisterLastBusValue = Array.fill(16, 0.0);
~twisterLastSetTime = Array.fill(16, -999999.0);
~controllerPanelInitialConfig = ~controllerPanelInitialConfig ? ();
~controllerInitialTwisterActive =
~controllerPanelInitialConfig[\twisterActive] ? [];
~controllerInitialSpectraActive =
~controllerPanelInitialConfig[\spectraActive] ? [];
~controllerInitialSpectraToggle =
~controllerPanelInitialConfig[\spectraToggle] ? [];
~controllerInitialSpectraDeterministic =
~controllerPanelInitialConfig[\spectraDeterministic] ? [];
if(
    ~controllerInitialSpectraToggle.any { |index|
        ~controllerInitialSpectraDeterministic.includes(index)
    },
    {
        Error(
            "A Spectra button cannot be both toggle and deterministic."
        ).throw;
    }
);
~twisterStatus = Array.fill(16, { |index|
    ~controllerInitialTwisterActive.includes(index).asInteger
});
~twisterActiveLED = 85; // red-ish
~spectraLastValue = Array.fill(16, -1);
~spectraToggle = Array.fill(16, { |index|
    ~controllerInitialSpectraToggle.includes(index)
});
~spectraToggleValue = Array.fill(16, 0);
~spectraDeterministic = Array.fill(16, { |index|
    ~controllerInitialSpectraDeterministic.includes(index)
});
~spectraButtonActive = Array.fill(16, 0);
~spectraStatus = Array.fill(16, { |index|
    ~controllerInitialSpectraActive.includes(index).asInteger
});
~spectraInactiveLED = 7;
~spectraActiveLED = 13;
~spectraPressedLED = 37; // bright yellow
~twisterData = Dictionary.new;
~spectraData = Dictionary.new;
~controllerPanelDeferOpen = ~controllerPanelDeferOpen ? false;
~controllerPanelIsDeferred = ~controllerPanelDeferOpen;
~controllerPanelDeferOpen = nil;

// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ PANEL CONFIGURATION │
// └─────────────────────────────────────────────────────────────────────────────┘
~controllerPanelMode = ~controllerPanelInitialConfig[\mode]
? (~controllerPanelInitialMode ? \prototype);
~controllerPanelControllers = ~controllerPanelInitialConfig[\controllers]
? (~controllerPanelInitialControllers ? \both);
~controllerPanelScale = 0.75;
~controllerPanelInitialConfig = nil;
~controllerPanelInitialMode = nil;
~controllerPanelInitialControllers = nil;
~controllerPerformanceContent = nil;
~controllerPerformanceSourceContent = Dictionary.new;
~controllerPanelModeHook = nil;

~setControllerPerformanceSourceContent = { |sourceName, contentFunction|
    ~controllerPerformanceSourceContent[sourceName.asSymbol] = contentFunction;
};

~clearControllerPerformanceSourceContent = {
    ~controllerPerformanceSourceContent.clear;
};

~twisterLabels = Array.fill(16, { |index| "KNOB " ++ index });
~spectraLabels = Array.fill(16, { |index| "BUTTON " ++ index });
~twisterColumnNames = Array.fill(4, "");
~twisterDisplayMins = Array.fill(16, 0.0);
~twisterDisplayMaxes = Array.fill(16, 1.0);

~refreshControllerPanel = {
    if(~controllerPanelIsDeferred.not, {
        ~makeCombinedPanel.tryPerform(\value);
    });
};

~setControllerPanelMode = { |mode = \prototype|
    if([\prototype, \performance].includes(mode), {
        ~controllerPanelMode = mode;
        ~controllerPanelModeHook.tryPerform(\value, mode);
        ~refreshControllerPanel.();
    }, {
        "Panel mode must be \\prototype or \\performance.".warn;
    });
};

~setControllerPanelControllers = { |controllers = \both|
    if([\twister, \spectra, \both].includes(controllers), {
        ~controllerPanelControllers = controllers;
        ~refreshControllerPanel.();
    }, {
        "Controller view must be \\twister, \\spectra, or \\both.".warn;
    });
};
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ CONTROL BUSSES │
// └─────────────────────────────────────────────────────────────────────────────┘
~twisterBusses = ~knobs.collect { Bus.control(s, 1).set(0.0) };
~spectraBusses = ~buttons.collect { Bus.control(s, 1).set(0.0) };
