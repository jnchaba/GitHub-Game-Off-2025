extends Control

@onready var current_waveform = $PanelContainer/VBoxContainer/CurrentContainer/CurrentWaveForm
@onready var fm_strength_overlay = $PanelContainer/VBoxContainer/ControlsContainer/ControlRowThree/FMStrengthContainer/FMStrengthHider
@onready var fm_rate_overlay = $PanelContainer/VBoxContainer/ControlsContainer/ControlRowTwo/FMRateContainer/FMRateHider
@onready var am_strength_overlay = $PanelContainer/VBoxContainer/ControlsContainer/ControlRowThree/AMStrengthContainer/AMStrengthHider
@onready var am_rate_overlay = $PanelContainer/VBoxContainer/ControlsContainer/ControlRowTwo/AMRateContainer/AMRateHider
@onready var puzzle_counter_label = $PanelContainer/VBoxContainer/CounterContainer/PuzzleCounter
@onready var attempt_counter_label = $PanelContainer/VBoxContainer/CounterContainer/AttemptCounter
@onready var success_panel = $PanelContainer/SuccessPanel
@onready var success_attempts_label = $PanelContainer/SuccessPanel/VBoxContainer/HBoxContainer/SuccessAttemptsLabel
@onready var completion_screen = $PanelContainer/CompletionPanel
@onready var completion_attempts_label = $PanelContainer/CompletionPanel/VBoxContainer/HBoxContainer/CompletionAttemptsLabel
@onready var puzzle_manager = $PuzzleManager


func _ready():
	# Subscribe to EventBus
	EventBus.puzzle_loaded.connect(_on_puzzle_loaded)
	EventBus.puzzle_attempt_made.connect(_on_puzzle_attempt_made)
	EventBus.puzzle_completed.connect(_on_puzzle_completed)
	EventBus.all_puzzles_completed.connect(_on_all_puzzles_completed)

	# Connect puzzle manager to target waveform
	var target_waveform = $PanelContainer/VBoxContainer/TargetContainer/TargetWaveForm
	puzzle_manager.set_target_waveform(target_waveform)


func _on_puzzle_loaded(puzzle_id: int, unlocked_controls: Array):
	print("UI: _on_puzzle_loaded(puzzle_id=%d)" % puzzle_id)

	# Hide success panel (in case we're coming from a completed puzzle)
	success_panel.visible = false

	# Update puzzle counter
	puzzle_counter_label.text = "Puzzle %d of 5" % (puzzle_id + 1)

	# Reset current waveform
	print("UI: Resetting current waveform to defaults")
	current_waveform.reset_to_defaults()

	# Update each control overlay individually
	fm_strength_overlay.visible = !(GameEnums.ControlType.FM_STRENGTH in unlocked_controls)
	fm_rate_overlay.visible = !(GameEnums.ControlType.FM_RATE in unlocked_controls)
	am_strength_overlay.visible = !(GameEnums.ControlType.AM_STRENGTH in unlocked_controls)
	am_rate_overlay.visible = !(GameEnums.ControlType.AM_RATE in unlocked_controls)
	print("UI: FM overlays visible: strength=%s, rate=%s" % [fm_strength_overlay.visible, fm_rate_overlay.visible])
	print("UI: AM overlays visible: strength=%s, rate=%s" % [am_strength_overlay.visible, am_rate_overlay.visible])


func _on_puzzle_attempt_made(success: bool, attempt_count: int):
	# Update attempt counter
	attempt_counter_label.text = "Attempts: %d" % attempt_count
	# Show failure feedback if needed
	if !success:
		# Flash the similarity bar red or shake it
		pass  # TODO: Add visual feedback

func _on_puzzle_completed(puzzle_id: int, total_attempts: int):
	# Show success panel
	success_panel.visible = true
	success_attempts_label.text = "Total Attempts: %d" % total_attempts

# Update success panel text if needed
func _on_all_puzzles_completed(total_attempts: int):
	# Show completion screen
	completion_screen.visible = true
	completion_attempts_label.text = "Total Attempts: %d" % total_attempts
	# completion_screen.set_stats(total_attempts) or similar

func _on_success_next_puzzle_button_pressed() -> void:
	print("UI: Next Puzzle button pressed")
	success_panel.visible = false
	puzzle_manager.next_puzzle()

func _on_completion_restart_button_pressed() -> void:
	completion_screen.visible = false
	puzzle_manager.restart_sequence()

func _on_lock_signal_button_pressed() -> void:
	EventBus.pub_lock_signal_button_pressed()
