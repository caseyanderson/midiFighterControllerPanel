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
~twisterStatus = Array.fill(16, 0);
~twisterActiveLED = 85; // red-ish
~spectraLastValue = Array.fill(16, -1);
~twisterData = Dictionary.new;
~spectraData = Dictionary.new;
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ CONTROL BUSSES │
// └─────────────────────────────────────────────────────────────────────────────┘
~twisterBusses = ~knobs.collect { Bus.control(s, 1).set(0.0) };
~spectraBusses = ~buttons.collect { Bus.control(s, 1).set(0.0) };