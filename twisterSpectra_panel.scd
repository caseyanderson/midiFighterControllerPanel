// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ GUI CREATION & LAYOUT │
// └─────────────────────────────────────────────────────────────────────────────┘
~makeCombinedPanel = {
	var twisterStrips, spectraStrips;
	twisterStrips = ~knobs.collect(~twisterLayout.(_));
	spectraStrips = ~buttons.collect(~spectraLayout.(_));
	if(~combinedPanel.notNil, { ~combinedPanel.close });
	~twisterData[\twisterStrips] = twisterStrips;
	~spectraData[\spectraStrips] = spectraStrips;
	~twisterColumnLabels = 4.collect {
		StaticText()
			.align_(\center)
			.string_("")
			.fixedWidth_(80)
			.minHeight_(0)
			.maxHeight_(18);
	};
	~combinedPanel = Window.new("Twister + Spectra Control Panel", Rect(0,0,892,692))
		.alwaysOnTop_(true)
		.layout_(
			VLayout(
				HLayout(
					VLayout(
						HLayout(*~twisterColumnLabels).spacing_(10),
						GridLayout.rows(
							*twisterStrips.clump(4).collect { |row| row.collect { |strip| strip[\layout] } }
						).hSpacing_(10).vSpacing_(10)
					),
					GridLayout.rows(
						*spectraStrips.clump(4).collect { |row| row.collect { |strip| strip[\layout] } }
					).hSpacing_(10).vSpacing_(10)
				).spacing_(10),
				HLayout(
					nil,
					Button()
						.minSize_(170@34)
						.states_([
							["Knobs All Off", Color.black, Color.gray],
							["Knobs All On", Color.white, Color.red]
						])
						.value_(0)
						.action_({ |but|
							if(but.value == 1, ~enableAllTwisterStatus, ~disableAllTwisterStatus);
						}),
					Button()
						.minSize_(170@34)
						.states_([
							["Buttons All Off", Color.black, Color.gray],
							["Buttons All On", Color.white, Color.red]
						])
						.value_(0)
						.action_({ |but|
							if(but.value == 1, { ~enableSpectraStatus.(16) }, ~disableAllSpectraStatus);
						}),
					nil
				).margins_([5,4,5,6])
			)
		)
		.front;
	~combinedPanel.bounds_(
		Rect(
			(Window.screenBounds.width - 892) / 2,
			(Window.screenBounds.height - 692) / 2,
			892,
			692
		)
	);
};