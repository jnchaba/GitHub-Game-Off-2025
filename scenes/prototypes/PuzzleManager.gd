extends Node
class_name PuzzleManager

## Puzzle Manager
## Orchestrates the 5-puzzle sequence, manages state, coordinates via EventBus

var puzzles: Array[SignalPuzzle] = []
var current_puzzle_index: int = 0
@onready var current_waveform = $"../PanelContainer/VBoxContainer/CurrentContainer/CurrentWaveForm"
var current_attempt_count: int = 0
var total_attempts_all_puzzles: int = 0
var current_state: GameEnums.PuzzleState = GameEnums.PuzzleState.NOT_STARTED

# Reference to target waveform (set in _ready)
var target_waveform: WaveformDrawer

func _ready() -> void:
	# Load preset puzzles
	puzzles = SignalPuzzle.create_preset_puzzles()

	# Subscribe to EventBus signals
	EventBus.lock_signal_button_pressed.connect(_on_lock_signal_pressed)
	EventBus.tutorial_dismissed.connect(_on_tutorial_dismissed)

	# Start first puzzle
	load_puzzle(0)

func load_puzzle(index: int) -> void:
	"""Load a puzzle by index and configure the target waveform"""
	print("=== PuzzleManager: load_puzzle(%d) ===" % index)

	if index < 0 or index >= puzzles.size():
		print("ERROR: Invalid puzzle index: %d" % index)
		return

	current_puzzle_index = index
	current_attempt_count = 0
	var puzzle = puzzles[index]

	print("Puzzle ID: %d, Name: %s" % [puzzle.puzzle_id, puzzle.difficulty_name])
	print("Tutorial text: '%s'" % puzzle.tutorial_text)
	print("Target params: freq=%.1f, amp=%.1f, fm_str=%.1f, fm_rate=%.1f, am_str=%.1f, am_rate=%.1f" %
		[puzzle.target_frequency, puzzle.target_amplitude, puzzle.target_fm_strength,
		 puzzle.target_fm_rate, puzzle.target_am_strength, puzzle.target_am_rate])

	# Show tutorial if needed
	if puzzle.tutorial_text != "":
		print("Showing tutorial...")
		current_state = GameEnums.PuzzleState.SHOWING_TUTORIAL
		EventBus.pub_show_tutorial(puzzle.tutorial_text)
		EventBus.pub_puzzle_loaded(puzzle.puzzle_id, puzzle.unlocked_controls)
		return  # Wait for tutorial_dismissed signal

	print("No tutorial - starting puzzle immediately")
	_start_puzzle(puzzle)

func _start_puzzle(puzzle: SignalPuzzle) -> void:
	"""Actually start the puzzle after tutorial (if any) is dismissed"""
	print("_start_puzzle() called for puzzle %d" % puzzle.puzzle_id)
	current_state = GameEnums.PuzzleState.IN_PROGRESS

	# Apply target parameters to target waveform
	if target_waveform:
		print("Applying target parameters to target waveform...")
		target_waveform.frequency = puzzle.target_frequency
		target_waveform.amplitude = puzzle.target_amplitude
		target_waveform.fm_strength = puzzle.target_fm_strength
		target_waveform.fm_rate = puzzle.target_fm_rate
		target_waveform.am_strength = puzzle.target_am_strength
		target_waveform.am_rate = puzzle.target_am_rate
		target_waveform.queue_redraw()
		print("Target waveform updated: freq=%.1f, amp=%.1f" % [target_waveform.frequency, target_waveform.amplitude])
	else:
		print("ERROR: target_waveform is null!")

	# Publish puzzle loaded event with unlocked controls
	print("Publishing puzzle_loaded event with %d unlocked controls" % puzzle.unlocked_controls.size())
	EventBus.pub_puzzle_loaded(puzzle.puzzle_id, puzzle.unlocked_controls)

func _on_tutorial_dismissed() -> void:
	"""Called when user dismisses the tutorial popup"""
	if current_state == GameEnums.PuzzleState.SHOWING_TUTORIAL:
		var puzzle = puzzles[current_puzzle_index]
		_start_puzzle(puzzle)

func _on_lock_signal_pressed() -> void:
	"""Called when LOCK SIGNAL button is pressed"""
	if current_state != GameEnums.PuzzleState.IN_PROGRESS:
		return  # Ignore if not in progress

	# Get similarity score from WaveformDrawer (it's already computed in _process)
	# We'll check if it's >= 95% (the lock threshold)
	var success = _check_if_locked()

	current_attempt_count += 1
	total_attempts_all_puzzles += 1

	EventBus.pub_puzzle_attempt_made(success, current_attempt_count)

	if success:
		_on_puzzle_success()

func _check_if_locked() -> bool:
	"""Check if the current similarity score meets the lock threshold"""
	# Get reference to current waveform from scene
	# (You'll need to pass this reference similar to target_waveform)
	return current_waveform.can_lock_signal() if current_waveform else false

func _on_puzzle_success() -> void:
	"""Called when puzzle is successfully locked"""
	print("=== Puzzle %d SUCCESS! ===" % current_puzzle_index)
	EventBus.pub_play_success_sound(true)
	current_state = GameEnums.PuzzleState.LOCKED_SUCCESS

	var puzzle = puzzles[current_puzzle_index]
	print("Publishing puzzle_completed event (attempts: %d)" % current_attempt_count)
	EventBus.pub_puzzle_completed(puzzle.puzzle_id, current_attempt_count)

	# Check if this was the last puzzle
	if current_puzzle_index >= puzzles.size() - 1:
		print("This was the LAST puzzle - showing completion screen")
		_on_all_puzzles_completed()
	else:
		print("More puzzles remaining (waiting for user to click Next Puzzle)")

func next_puzzle() -> void:
	"""Load the next puzzle in the sequence"""
	print("=== next_puzzle() called, current index: %d ===" % current_puzzle_index)
	if current_puzzle_index < puzzles.size() - 1:
		load_puzzle(current_puzzle_index + 1)
	else:
		print("WARNING: Already on last puzzle!")

func _on_all_puzzles_completed() -> void:
	"""Called when all 5 puzzles are completed"""
	current_state = GameEnums.PuzzleState.COMPLETED
	EventBus.pub_all_puzzles_completed(total_attempts_all_puzzles)

func restart_sequence() -> void:
	"""Restart from puzzle 1"""
	total_attempts_all_puzzles = 0
	load_puzzle(0)

## Helper method to set target waveform reference (called from scene)
func set_target_waveform(waveform: WaveformDrawer) -> void:
	target_waveform = waveform
