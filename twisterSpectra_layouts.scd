// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ GUI LAYOUT HELPERS │
// └─────────────────────────────────────────────────────────────────────────────┘
~twisterLayout = { |knobNum|
	var statusButton, knob, knobValDisplay, view;
	statusButton = Button()
		.minSize_(80@30)
		.states_([
			["KNOB " ++ knobNum, Color.black, Color.gray],
			["KNOB " ++ knobNum, Color.white, Color.red]
		])
		.value_(0);
	statusButton.action_({ |but|
		~setTwisterStatus.(knobNum, but.value == 1);
	});
	knob = Knob().minSize_(80@80).value_(0.0);
	knobValDisplay = NumberBox()
		.minSize_(80@30)
		.align_(\center)
		.value_(0.0)
		.decimals_(3);
	view = View().background_(Color.gray(0.9))
		.layout_(VLayout(statusButton, knob, knobValDisplay).spacing_(5).margins_([10,5,10,5]));
	IdentityDictionary[
		\layout -> view,
		\button -> statusButton,
		\knob -> knob,
		\number2 -> knobValDisplay,
		\dispMin -> 0.0,
		\dispMax -> 1.0
	];
};
~spectraLayout = { |buttonNum|
	var statusButton, button, view;
	statusButton = Button()
		.minSize_(80@30)
		.states_([
			["BUTTON " ++ buttonNum, Color.black, Color.gray],
			["BUTTON " ++ buttonNum, Color.white, Color.red]
		])
		.value_(0);
	statusButton.action_({ |but|
		if(but.value == 0, { button.valueAction_(0); });
	});
	button = Button()
		.minSize_(80@80)
		.states_([
			["OFF", Color.black, Color.gray],
			["ON", Color.white, Color.red]
		])
		.value_(0);
	view = View().background_(Color.gray(0.9))
		.layout_(VLayout(statusButton, button).spacing_(5).margins_([10,5,10,5]));
	IdentityDictionary[
		\layout -> view,
		\button1 -> statusButton,
		\button2 -> button
	];
};
