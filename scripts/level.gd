class_name Level

var caption: String
var input: Array[int]
var instructions_allowed: Array[String]
var expected_output: Array[int]
var available_registers: Array[int]
var description: String

static func create_level(_caption: String, _input: Array[int], _instructions_allowed: Array[String], 
		   _expected_output: Array[int], _available_registers: Array[int],
		   _description: String) -> Level:
	var l = Level.new()
	l.caption = _caption
	l.input = _input
	l.instructions_allowed = _instructions_allowed
	l.expected_output = _expected_output
	l.available_registers = _available_registers
	l.description = _description
	return l

static var default_levels: Array[Level] = [
	create_level("In and Out", [1, 2], ["inbox", "outbox"], [1, 2], [], "Put every input box onto the output conveyer."),
	create_level("Pair Subtraction",
				 [3, 9, 5, 1, -2, -2, 9, -9], 
				 ["inbox", "outbox", "copyfrom", "copyto", "add", "sub", "jump", "jumpifzero"],
				 [-6, 6, 4, -4, 0, 0, 18, -18],
				 [0, 1, 2],
				 "For each pair of input boxes, subtract the second from the first, and put the result onto the output conveyer; then subtract the first from the second, and put the result onto the conveyer."),
	create_level("Equal Pair",
				 [6, 2, 7, 7, -9, 3, -3, -3],
				 ["inbox", "outbox", "copyfrom", "copyto", "add", "sub", "jump", "jumpifzero"],
				 [7, -3],
				 [0, 1, 2],
				 "For each pair of input boxes, output one of them if they are equal, otherwise drop them."),
	create_level("Deduplication",
				 [3, 3, 3, 0, 2, 2, 2, 8, 8, 8],
				 ["inbox", "outbox", "copyfrom", "copyto", "add", "sub", "jump", "jumpifzero"],
				 [3, 0, 2, 8],
				 [0, 1, 2],
				 "For any repeating sequence in the input, only output one repeating element.")
]
