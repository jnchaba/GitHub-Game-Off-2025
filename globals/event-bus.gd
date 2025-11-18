extends Node

# -- UI signals --
signal ui_loaded(value: bool)
signal play_dial_click()
signal play_success_sound(value: bool)
signal current_frequency_changed(value: float)
signal current_fm_depth_changed(value: float)
signal current_amplitude_changed(value: float)
signal current_am_depth_changed(value: float)
signal signal_similarty_score_changed(value: float)

# -- Puzzle System signals --
signal puzzle_loaded(puzzle_id: int, unlocked_controls: Array)
signal puzzle_attempt_made(success: bool, attempt_count: int)
signal puzzle_completed(puzzle_id: int, total_attempts: int)
signal show_tutorial(tutorial_text: String)
signal tutorial_dismissed()
signal all_puzzles_completed(total_attempts: int)
signal lock_signal_button_pressed()

# -- Publish helpers
func pub_ui_loaded(v: bool) -> void:
	emit_signal("ui_loaded", v)

func pub_play_dial_click() -> void:
	emit_signal("play_dial_click")

func pub_play_success_sound(success: bool) -> void:
	emit_signal("play_success_sound", success)

func pub_current_frequency_changed(v: float):
	emit_signal("current_frequency_changed", v) 

func pub_current_amplitude_changed(v: float):
	emit_signal("current_amplitude_changed", v)

func pub_current_fm_depth_changed(v: float):
	emit_signal("current_fm_depth_changed", v)

func pub_current_am_depth_changed(v: float):
	emit_signal("current_am_depth_changed", v)

func pub_signal_similarty_score_changed(v: float):
	emit_signal("signal_similarty_score_changed", v)

# -- Puzzle System publishers --
func pub_puzzle_loaded(puzzle_id: int, unlocked_controls: Array) -> void:
	emit_signal("puzzle_loaded", puzzle_id, unlocked_controls)

func pub_puzzle_attempt_made(success: bool, attempt_count: int) -> void:
	emit_signal("puzzle_attempt_made", success, attempt_count)

func pub_puzzle_completed(puzzle_id: int, total_attempts: int) -> void:
	emit_signal("puzzle_completed", puzzle_id, total_attempts)

func pub_show_tutorial(tutorial_text: String) -> void:
	emit_signal("show_tutorial", tutorial_text)

func pub_tutorial_dismissed() -> void:
	emit_signal("tutorial_dismissed")

func pub_all_puzzles_completed(total_attempts: int) -> void:
	emit_signal("all_puzzles_completed", total_attempts)

func pub_lock_signal_button_pressed() -> void:
	emit_signal("lock_signal_button_pressed")
