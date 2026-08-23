// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ GUI CREATION & LAYOUT │
// └─────────────────────────────────────────────────────────────────────────────┘
~makeCombinedPanel = {
    var panelHeight, panelWidth, performanceContent, performanceItems, performanceSources, sizeHint;
    var footerControls, spectraIndices, spectraStrips, twisterIndices, twisterStrips;
	var spectraGrid, spectraLayout, topLayout, twisterLayout;

    panelWidth = ~controllerPanelSize.(892);
    panelHeight = ~controllerPanelSize.(692);

    twisterIndices = if(~controllerPanelMode == \prototype, {
        ~knobs
    }, {
        ~knobs.select { |index| ~twisterStatus[index] == 1 }
    });
    spectraIndices = if(~controllerPanelMode == \prototype, {
        ~buttons
    }, {
        ~buttons.select { |index| ~spectraStatus[index] == 1 }
    });

    if(~controllerPanelControllers == \spectra, {
        twisterIndices = [];
    });
    if(~controllerPanelControllers == \twister, {
        spectraIndices = [];
    });

    twisterStrips = Array.newClear(16);
    twisterIndices.do { |index|
        twisterStrips[index] = ~twisterLayout.(index);
    };
    spectraStrips = Array.newClear(16);
    spectraIndices.do { |index|
        spectraStrips[index] = ~spectraLayout.(index);
    };

    ~twisterData[\twisterStrips] = twisterStrips;
    ~spectraData[\spectraStrips] = spectraStrips;

    ~twisterColumnLabels = 4.collect { |column|
        StaticText()
        .align_(\center)
        .string_(~twisterColumnNames[column])
        .fixedWidth_(~controllerPanelSize.(80))
        .fixedHeight_(~controllerPanelSize.(18));
    };

    if(twisterIndices.notEmpty, {
        twisterLayout = if(~controllerPanelMode == \prototype, {
            VLayout(
                [
                    HLayout(*~twisterColumnLabels)
                    .spacing_(~controllerPanelSize.(10))
                    , stretch: 0
                ],
                GridLayout.rows(
                    *twisterIndices.clump(4).collect { |row|
                        row.collect { |index|
                            twisterStrips[index][\layout]
                        }
                    }
                )
                .hSpacing_(~controllerPanelSize.(10))
                .vSpacing_(~controllerPanelSize.(10))
            )
        }, {
            HLayout(*4.collect { |column|
                var columnIndices = twisterIndices.select { |index|
                    index % 4 == column
                };

                if(columnIndices.notEmpty, {
                    VLayout(*(
                        [[~twisterColumnLabels[column], stretch: 0]]
                        ++ columnIndices.collect { |index|
                            [twisterStrips[index][\layout], stretch: 0]
                        }
                        ++ [nil]
                    ));
                }, {
                    nil
                });
            }.reject(_.isNil))
            .spacing_(~controllerPanelSize.(10))
        });
	});

	if(spectraIndices.notEmpty, {
		spectraGrid = GridLayout.rows(
			*spectraIndices.clump(4).collect { |row|
				row.collect { |index|
					spectraStrips[index][\layout]
                }
            }
		)
		.hSpacing_(~controllerPanelSize.(10))
		.vSpacing_(~controllerPanelSize.(10));

		spectraLayout = if(~controllerPanelMode == \prototype, {
			VLayout(
				[
					HLayout(*4.collect {
					StaticText()
					.fixedWidth_(~controllerPanelSize.(80))
					.minHeight_(0)
					.maxHeight_(~controllerPanelSize.(18));
				})
				.spacing_(~controllerPanelSize.(10))
					, stretch: 0
				],
				spectraGrid
			);
		}, {
			VLayout(
				[StaticText().fixedHeight_(~controllerPanelSize.(18)), stretch: 0],
				[
					HLayout(*spectraIndices.collect { |index|
						spectraStrips[index][\layout]
					})
					.spacing_(~controllerPanelSize.(10)),
					stretch: 0
				],
				nil
			);
		});
	});

    performanceContent = if(
        ~controllerPanelMode == \performance
        and: { ~controllerPerformanceContent.notNil },
        { ~controllerPerformanceContent.value },
        { nil }
    );

    performanceItems = if(~controllerPanelMode == \performance, {
        performanceSources = List.new;

        twisterIndices.do { |index|
            var sourceKey = ~twisterColumnNames[index % 4].asSymbol;

            if(sourceKey.asString.size > 0 and: {
                performanceSources.includes(sourceKey).not
            }, {
                performanceSources.add(sourceKey);
            });
        };

        spectraIndices.do { |index|
            var sourceKey = ~spectraLabels[index].asSymbol;

            if(sourceKey.asString.size > 0 and: {
                performanceSources.includes(sourceKey).not
            }, {
                performanceSources.add(sourceKey);
            });
        };

        ~controllerPerformanceSourceContent.keys.do { |sourceKey|
            if(performanceSources.includes(sourceKey).not, {
                performanceSources.add(sourceKey);
            });
        };

        performanceSources.collect { |sourceKey|
            var channelBody, channelStrip, channelTitle, content;
            var gainParts, gainStageView, notchX, notchY;
            var placeGainStageChildren;
            var performanceSpectraStrip;
            var rightColumn, sourceSpectra, sourceTwister, spectraColumn, twisterColumn;

            sourceTwister = twisterIndices.select { |index|
                ~twisterColumnNames[index % 4].asSymbol == sourceKey
            };
            sourceSpectra = spectraIndices.select { |index|
                ~spectraLabels[index].asSymbol == sourceKey
            };
            content = ~controllerPerformanceSourceContent[sourceKey]
            .tryPerform(\value);

            twisterColumn = if(sourceTwister.notEmpty, {
                VLayout(*(
                    sourceTwister.collect { |index|
                        [twisterStrips[index][\layout], stretch: 0]
                    }
                    ++ [nil]
                )).spacing_(~controllerPanelSize.(10));
            });

            spectraColumn = if(sourceSpectra.notEmpty, {
                VLayout(*(
                    sourceSpectra.collect { |index|
                        [spectraStrips[index][\layout], stretch: 0]
                    }
                    ++ [nil]
                ));
            });

            rightColumn = if(content.notNil and: {
                content.tryPerform(\at, \type) == \gainStage
            }, {
                var gap = ~controllerPanelSize.(10);
                var controlWidth = content[\controlWidth];
                var meterColumnWidth = content[\meterColumnWidth];
                var spectraHeight = if(sourceSpectra.notEmpty, {
                    ~controllerPanelSize.(160);
                }, {
                    0;
                });
                var stageHeight, stageWidth;

                notchX = controlWidth + gap;
                notchY = if(sourceSpectra.notEmpty, {
                    spectraHeight + gap;
                }, {
                    0;
                });

                stageWidth = notchX + meterColumnWidth;
                stageHeight = notchY
                + content[\controlHeight]
                + gap
                + content[\controlHeight];

                gainStageView = View()
                .fixedSize_(stageWidth @ stageHeight);

                if(sourceSpectra.notEmpty, {
                    performanceSpectraStrip = ~spectraLayout.(
                        sourceSpectra[0],
                        gainStageView,
                        Rect(0, 0, controlWidth, spectraHeight)
                    );
                    spectraStrips[sourceSpectra[0]] = performanceSpectraStrip;
                    ~spectraData[\spectraStrips][sourceSpectra[0]] = performanceSpectraStrip;
                });

                gainParts = content[\build].(
                    gainStageView,
                    Rect(0, notchY, controlWidth, content[\controlHeight]),
                    Rect(
                        0,
                        notchY + content[\controlHeight] + gap,
                        controlWidth,
                        content[\controlHeight]
                    ),
                    Rect(
                        notchX,
                        0,
                        content[\meterWidth],
                        stageHeight
                    )
                );

                placeGainStageChildren = {
                    if(performanceSpectraStrip.notNil, {
                        performanceSpectraStrip[\layout].bounds_(
                            Rect(0, 0, controlWidth, spectraHeight)
                        );
                    });

                    gainParts[\makeup].bounds_(
                        Rect(0, notchY, controlWidth, content[\controlHeight])
                    );
                    gainParts[\trim].bounds_(Rect(
                        0,
                        notchY + content[\controlHeight] + gap,
                        controlWidth,
                        content[\controlHeight]
                    ));
                };

                gainStageView.onResize_({ placeGainStageChildren.() });
                placeGainStageChildren.();

                gainStageView;
            }, {
                if(spectraColumn.notNil and: { content.notNil }, {
                VLayout(
                    [spectraColumn, stretch: 0],
                    [content, stretch: 0],
                    nil
                );
                }, {
                    spectraColumn ? content;
                });
            });

            channelBody = HLayout(*(
                (if(twisterColumn.notNil, {
                    [[twisterColumn, stretch: 0, align: \top]];
                }, {
                    [];
                })) ++ (if(rightColumn.notNil, {
                    [[rightColumn, stretch: 0, align: \top]];
                }, {
                    [];
                })) ++ [nil]
            ))
            .spacing_(~controllerPanelSize.(10));

            channelTitle = StaticText()
            .string_(sourceKey.asString)
            .align_(\center)
            .fixedHeight_(~controllerPanelSize.(18));

            channelStrip = View()
            .layout_(VLayout(
                [channelTitle, stretch: 0],
                [channelBody, stretch: 0],
                nil
            ));

            if(content.notNil and: {
                content.tryPerform(\at, \type) == \gainStage
            }, {
                channelStrip.fixedWidth_(
                    (if(sourceTwister.notEmpty, {
                        ~controllerPanelSize.(100) + ~controllerPanelSize.(10);
                    }, {
                        0;
                    })) + notchX + content[\meterColumnWidth]
                );
            });

            [channelStrip, stretch: 0, align: \top];
        };
    }, {
        [];
    });

    topLayout = if(~controllerPanelMode == \performance, {
        HLayout(*performanceItems)
        .spacing_(~controllerPanelSize.(10));
    }, {
        HLayout(
            if(twisterLayout.notNil, { [twisterLayout, align: \top] }),
            if(spectraLayout.notNil, { [spectraLayout, align: \top] }),
            performanceContent
        )
        .spacing_(~controllerPanelSize.(10));
    });

    footerControls = [
        if(twisterIndices.notEmpty, {
            Button()
            .fixedSize_(~controllerPanelSize.(170) @ ~controllerPanelSize.(34))
            .states_([
                ["Knobs All Off", Color.black, Color.gray],
                ["Knobs All On", Color.white, Color.red]
            ])
            .value_(0)
            .action_({ |button|
                if(button.value == 1, {
                    ~enableAllTwisterStatus.();
                }, {
                    ~disableAllTwisterStatus.();
                });
            });
        }),

        if(spectraIndices.notEmpty, {
            Button()
            .fixedSize_(~controllerPanelSize.(170) @ ~controllerPanelSize.(34))
            .states_([
                ["Buttons All Off", Color.black, Color.gray],
                ["Buttons All On", Color.white, Color.red]
            ])
            .value_(0)
            .action_({ |button|
                if(button.value == 1, {
                    ~enableSpectraStatus.(16);
                }, {
                    ~disableAllSpectraStatus.();
                });
            });
        })
    ].reject(_.isNil);

    if(~combinedPanel.notNil, {
        ~combinedPanel.onClose_(nil);
        ~combinedPanel.close;
    });

    ~combinedPanel = Window.new(
        "Twister + Spectra Control Panel",
        Rect(0, 0, panelWidth, panelHeight)
    )
    .alwaysOnTop_(true)
    .layout_(if(~controllerPanelMode == \performance, {
        VLayout(
            [topLayout, stretch: 0],
            nil
        );
    }, {
        VLayout(
            [topLayout, align: \top],

            HLayout(
                [View(), stretch: 1],
                [HLayout(*footerControls), stretch: 0],
                [View(), stretch: 1]
            )
            .margins_([
                ~controllerPanelSize.(5),
                ~controllerPanelSize.(4),
                ~controllerPanelSize.(5),
                ~controllerPanelSize.(6)
            ]);
        )
    }))
    .front;

    {
        sizeHint = ~combinedPanel.minSizeHint;
        panelWidth = sizeHint.width;
        panelHeight = sizeHint.height;

        ~combinedPanel.bounds_(Rect(
            (Window.screenBounds.width - panelWidth) / 2,
            (Window.screenBounds.height - panelHeight) / 2,
            panelWidth,
            panelHeight
        ));
    }.defer;

    ~installTwisterKnobActions.tryPerform(\value);
    nil;
};
