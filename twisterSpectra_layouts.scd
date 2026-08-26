// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ GUI LAYOUT HELPERS │
// └─────────────────────────────────────────────────────────────────────────────┘
~controllerPanelSize = { |baseSize|
    (baseSize * ~controllerPanelScale).round.asInteger;
};

~twisterLayout = { |knobNum|
    var knob, knobValDisplay, statusButton, view;
    var label = ~twisterLabels[knobNum];
    var stripWidth = ~controllerPanelSize.(80);
    var knobSize = ~controllerPanelSize.(80);
    var smallHeight = ~controllerPanelSize.(30);

    knob = Knob()
    .minSize_(knobSize @ knobSize)
    .value_(~twisterLastBusValue[knobNum] ? 0.0);

    knobValDisplay = NumberBox()
    .minSize_(stripWidth @ smallHeight)
    .align_(\center)
    .value_(knob.value.linlin(
        0, 1,
        ~twisterDisplayMins[knobNum],
        ~twisterDisplayMaxes[knobNum]
    ))
    .decimals_(3);

    statusButton = if(~controllerPanelMode == \prototype, {
        Button()
        .minSize_(stripWidth @ smallHeight)
        .states_([
            [label, Color.black, Color.gray],
            [label, Color.white, Color.red]
        ])
        .value_(~twisterStatus[knobNum]);
    }, {
        StaticText()
        .minSize_(stripWidth @ smallHeight)
        .fixedHeight_(smallHeight)
        .align_(\center)
        .string_(label)
        .stringColor_(if(~twisterStatus[knobNum] == 1, Color.white, Color.black))
        .background_(if(~twisterStatus[knobNum] == 1, Color.red, Color.gray));
    });

    if(~controllerPanelMode == \prototype, {
        statusButton.action_({ |button|
            ~setTwisterStatus.(knobNum, button.value == 1);
        });
    });

    view = View()
    .background_(Color.gray(0.9))
    .fixedWidth_(stripWidth + ~controllerPanelSize.(20))
    .layout_(VLayout(
        statusButton,
        knob,
        knobValDisplay
    )
    .spacing_(~controllerPanelSize.(5))
    .margins_([
        ~controllerPanelSize.(10),
        ~controllerPanelSize.(5),
        ~controllerPanelSize.(10),
        ~controllerPanelSize.(5)
    ]));

    if(~controllerPanelMode == \performance, {
        view.fixedHeight_(~controllerPanelSize.(160));
    });

    IdentityDictionary[
        \layout -> view,
        \button -> statusButton,
        \knob -> knob,
        \number2 -> knobValDisplay,
        \dispMin -> ~twisterDisplayMins[knobNum],
        \dispMax -> ~twisterDisplayMaxes[knobNum]
    ];
};

~spectraLayout = { |buttonNum, parent = nil, bounds = nil|
    var hidePerformanceLabel, statusButton, button, label, performanceLabel, view;
    var stripWidth = ~controllerPanelSize.(80);
    var buttonSize = ~controllerPanelSize.(80);
    var smallHeight = ~controllerPanelSize.(30);

    label = ~spectraLabels[buttonNum];
    button = Button()
    .minSize_(buttonSize @ buttonSize)
    .states_([
        ["OFF", Color.black, Color.gray],
        ["ON", Color.white, Color.red]
    ])
    .value_(if(
        ~spectraToggle[buttonNum],
        ~spectraToggleValue[buttonNum],
        if(
            ~spectraDeterministic[buttonNum],
            ~spectraButtonActive[buttonNum],
            0
        )
    ));

    hidePerformanceLabel = ~controllerPanelMode == \performance;

    performanceLabel = if(
        hidePerformanceLabel,
        { "" },
        { label }
    );

    statusButton = if(~controllerPanelMode == \prototype, {
        Button()
        .minSize_(stripWidth @ smallHeight)
        .states_([
            [label, Color.black, Color.gray],
            [label, Color.white, Color.red]
        ])
        .value_(~spectraStatus[buttonNum]);
    }, {
        StaticText()
        .minSize_(stripWidth @ smallHeight)
        .fixedHeight_(smallHeight)
        .align_(\center)
        .string_(performanceLabel)
        .font_(Font.default.size_(8))
        .stringColor_(if(hidePerformanceLabel, {
            Color.clear
        }, {
            if(~spectraStatus[buttonNum] == 1, Color.white, Color.black)
        }))
        .background_(if(hidePerformanceLabel, {
            Color.clear
        }, {
            if(~spectraStatus[buttonNum] == 1, Color.red, Color.gray)
        }));
    });

    if(~controllerPanelMode == \prototype, {
        statusButton.action_({ |status|
            ~setSpectraStatus.(buttonNum, status.value == 1);
        });
    });

    view = if(parent.notNil, {
        View(parent, bounds);
    }, {
        View();
    })
    .background_(Color.gray(0.9))
    .fixedWidth_(stripWidth + ~controllerPanelSize.(20))
    .layout_(VLayout(
        statusButton,
        button,
        StaticText().minSize_(stripWidth @ smallHeight)
    )
    .spacing_(~controllerPanelSize.(5))
    .margins_([
        ~controllerPanelSize.(10),
        ~controllerPanelSize.(5),
        ~controllerPanelSize.(10),
        ~controllerPanelSize.(5)
    ]));

    if(~controllerPanelMode == \performance, {
        view.fixedHeight_(~controllerPanelSize.(160));
    });

    IdentityDictionary[
        \layout -> view,
        \button1 -> statusButton,
        \button2 -> button
    ];
};
