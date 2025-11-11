extends Node

const DIAL_CLICK = "res://assets/sound-effects/ui-effects/click_004.ogg"
const SUCCESS = "res://assets/sound-effects/ui-effects/confirmation_001.ogg"
const FAILURE = "res://assets/sound-effects/ui-effects/error_008.ogg"

# === Control Types ===
enum ControlType {
	FREQUENCY,
	AMPLITUDE,
	FM_STRENGTH,
	FM_RATE,
	AM_STRENGTH,
	AM_RATE
}

# === Puzzle States ===
enum PuzzleState {
	NOT_STARTED,
	IN_PROGRESS,
	SHOWING_TUTORIAL,
	LOCKED_SUCCESS,
	COMPLETED
}
