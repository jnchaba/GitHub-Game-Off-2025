extends Resource
class_name SignalPuzzle

## Signal Puzzle Resource
## Defines a single puzzle configuration with target waveform parameters and control unlocking

@export var puzzle_id: int = 0
@export var difficulty_name: String = ""
@export var tutorial_text: String = ""  # Empty = no tutorial for this puzzle

# Target waveform parameters the player must match
@export var target_frequency: float = 5.0
@export var target_amplitude: float = 0.5
@export var target_fm_strength: float = 0.0
@export var target_fm_rate: float = 0.0
@export var target_am_strength: float = 0.0
@export var target_am_rate: float = 0.0

# Which controls are unlocked for this puzzle (uses GameEnums.ControlType)
@export var unlocked_controls: Array[int] = []

func _init(
	p_id: int = 0,
	p_difficulty: String = "",
	p_tutorial: String = "",
	p_freq: float = 5.0,
	p_amp: float = 0.5,
	p_fm_str: float = 0.0,
	p_fm_rate: float = 0.0,
	p_am_str: float = 0.0,
	p_am_rate: float = 0.0,
	p_unlocked: Array[int] = []
):
	puzzle_id = p_id
	difficulty_name = p_difficulty
	tutorial_text = p_tutorial
	target_frequency = p_freq
	target_amplitude = p_amp
	target_fm_strength = p_fm_str
	target_fm_rate = p_fm_rate
	target_am_strength = p_am_str
	target_am_rate = p_am_rate
	unlocked_controls = p_unlocked

## Create 5 preset puzzles for rapid prototyping
static func create_preset_puzzles() -> Array[SignalPuzzle]:
	var puzzles: Array[SignalPuzzle] = []

	# Puzzle 1: Tutorial - Only frequency and amplitude
	puzzles.append(SignalPuzzle.new(
		0,
		"Tutorial",
		"Welcome! Match the target waveform by adjusting FREQUENCY and AMPLITUDE.\n\nThe Signal Similarity Score must reach 95% or higher to lock the signal.",
		3.0,  # target_frequency (different from default 5.0)
		0.5,  # target_amplitude (same as default)
		0.0, 0.0, 0.0, 0.0,
		[GameEnums.ControlType.FREQUENCY, GameEnums.ControlType.AMPLITUDE]
	))

	# Puzzle 2: Two dials - still just frequency and amplitude
	puzzles.append(SignalPuzzle.new(
		1,
		"Basic Tuning",
		"",  # No tutorial - same controls as puzzle 1
		7.0,  # target_frequency
		0.8,  # target_amplitude (different from default)
		0.0, 0.0, 0.0, 0.0,
		[GameEnums.ControlType.FREQUENCY, GameEnums.ControlType.AMPLITUDE]
	))

	# Puzzle 3: FM Introduction
	puzzles.append(SignalPuzzle.new(
		2,
		"FM Introduction",
		"New controls unlocked!\n\nFM (Frequency Modulation) warps the frequency over time.\n- FM STRENGTH: How much the frequency varies\n- FM RATE: How fast the frequency oscillates\n\nMatch all four parameters to lock the signal.",
		4.0,  # target_frequency
		0.6,  # target_amplitude
		0.3,  # target_fm_strength (NEW!)
		0.5,  # target_fm_rate (NEW!)
		0.0, 0.0,
		[GameEnums.ControlType.FREQUENCY, GameEnums.ControlType.AMPLITUDE,
		 GameEnums.ControlType.FM_STRENGTH, GameEnums.ControlType.FM_RATE]
	))

	# Puzzle 4: Complex - no new controls, harder tuning
	puzzles.append(SignalPuzzle.new(
		3,
		"Complex Signal",
		"",  # No tutorial - same controls as puzzle 3
		6.5,  # target_frequency
		0.7,  # target_amplitude
		0.6,  # target_fm_strength (higher than before)
		0.8,  # target_fm_rate (higher than before)
		0.0, 0.0,
		[GameEnums.ControlType.FREQUENCY, GameEnums.ControlType.AMPLITUDE,
		 GameEnums.ControlType.FM_STRENGTH, GameEnums.ControlType.FM_RATE]
	))

	# Puzzle 5: Master - all 6 controls unlocked
	puzzles.append(SignalPuzzle.new(
		4,
		"Master Signal",
		"Final challenge!\n\nAM (Amplitude Modulation) controls unlocked.\n- AM STRENGTH: How much the amplitude varies\n- AM RATE: How fast the amplitude oscillates\n\nMatch all six parameters perfectly to complete the test.",
		5.5,  # target_frequency
		0.4,  # target_amplitude
		0.4,  # target_fm_strength
		0.3,  # target_fm_rate
		0.5,  # target_am_strength (NEW!)
		0.7,  # target_am_rate (NEW!)
		[GameEnums.ControlType.FREQUENCY, GameEnums.ControlType.AMPLITUDE,
		 GameEnums.ControlType.FM_STRENGTH, GameEnums.ControlType.FM_RATE,
		 GameEnums.ControlType.AM_STRENGTH, GameEnums.ControlType.AM_RATE]
	))

	return puzzles
