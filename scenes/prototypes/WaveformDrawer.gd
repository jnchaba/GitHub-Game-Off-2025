extends Control
class_name WaveformDrawer

@export_category("Calculation Settings")
@export var is_current: bool = false
@export var comparison_wave: NodePath  # target waveform node
@export var signal_similarity_bar: NodePath
@export var signal_lock_button: NodePath


@export_category("Amplitude Effects")
@export var amplitude: float = 0.5 # tremolo basically
@export var am_strength: float = 0.0  # How strong the AM effect is
@export var am_rate: float = 0.0  # How fast AM happens
@export_category("Frequency Effects")
@export var frequency: float = 5.0 # vibrato basically
@export var fm_strength: float = 0.0  # Amount of frequency warping
@export var fm_rate: float = 0.0  # Speed of frequency warping

@export var phase: float = 0.0
@export var line_color: Color = Color.html("#5EF1F2")
@export var thickness: float = 2.0
@export var samples: int = 256
@export var scroll_speed: float = 1.0

@export_category("Border")
@export var border_color: Color
@export var border_thickness = 2.0

@export_category("Background")
@export var background_grid_color : Color = Color(1, 1, 1, 0.05)
@export var background_grid_num_vertical_lines = 8
@export	var background_grid_num_horizontal_lines = 4

var _computed_similarity_score: float = 0.0
var _target_wave: WaveformDrawer
var _similarity_bar: ProgressBar
var _lock_button: Button
var _can_lock_signal := false

# === Lifecycle Methods ===

func _ready():
	if is_current:
		if comparison_wave != NodePath():
			_target_wave = get_node(comparison_wave)
		if signal_similarity_bar != NodePath():
			_similarity_bar = get_node(signal_similarity_bar)
		if signal_lock_button != NodePath():
			_lock_button = get_node(signal_lock_button)
			_lock_button.disabled = true
	queue_redraw()

func _process(delta: float) -> void:
	phase += scroll_speed * delta
	queue_redraw()
	if _target_wave:
		calculate_similarity()
	if _lock_button:
		_toggle_button()

# === Drawing Logic (Extract to WaveformRenderer later) ===

func _draw():
	if samples < 2:
		return

	var w = size.x
	var h = size.y
	var vertical_padding = 0.05  # 5% margin
	var drawing_height = h * (1.0 - vertical_padding * 2.0)
	var center_y = h / 2.0
	var half_height = drawing_height / 2.0
	
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_thickness)
	draw_background_grid(w, h, center_y)
	draw_waveform(w, center_y, half_height)


func draw_background_grid(w: float, h: float, center_y: float):
	# Vertical grid lines
	for i in range(1, background_grid_num_vertical_lines):
		var x = (w / background_grid_num_vertical_lines) * i
		draw_line(Vector2(x, 0), Vector2(x, h), background_grid_color, 1)

	# Horizontal grid lines
	for i in range(1, background_grid_num_horizontal_lines):
		var y = (h / background_grid_num_horizontal_lines) * i
		draw_line(Vector2(0, y), Vector2(w, y), background_grid_color, 1)

	# Optional center line (e.g. y = 0 axis)
	draw_line(Vector2(0, center_y), Vector2(w, center_y), Color(1, 1, 1, 0.1), 1.5)

func draw_waveform(w: float, center_y: float, half_height: float) -> void:
	var t0 = 0.0
	var x0 = 0.0
	var y0 = sin(t0 * TAU * frequency + phase) * amplitude
	var last_point = Vector2(x0, center_y + y0 * half_height)

	for i in range(samples + 1):
		var t = float(i) / samples
		var x = t * w

		# Frequency Modulation
		var mod_freq = frequency + fm_strength * sin(t * TAU * fm_rate + phase)

		# Amplitude Modulation
		var mod_amp = 1.0 + am_strength * sin(t * TAU * am_rate + phase)

		# Normalized Y in [-1, 1] space
		var y_norm = sin(t * TAU * mod_freq + phase) * amplitude * mod_amp
		# Compute dynamic total amp modulation factor
		var total_amp = amplitude * (1.0 + abs(am_strength))
		var waveScale = min(1.0, 1.0 / total_amp)
		y_norm *= waveScale
		
		var y = center_y + y_norm * half_height

		var point = Vector2(x, y)

		if i > 0:
			draw_line(last_point, point, line_color, thickness)

		last_point = point

# === Signal Matching Logic (Extract to SignalMatchingService later) ===

func calculate_similarity() -> void:
	if not _target_wave:
		return

	var similarity = _compute_waveform_similarity(_target_wave)
	_update_similarity_ui(similarity)
	_update_signal_lock_state(similarity)

func _compute_waveform_similarity(target: WaveformDrawer) -> float:
	"""
	Computes similarity between current and target waveforms.
	Uses "worst parameter" approach - ALL dials must be tuned accurately.
	Returns: 0.0 (completely different) to 1.0 (perfect match)
	"""
	var parameter_diffs = _calculate_parameter_differences(target)
	var max_diff = _get_worst_parameter_difference(parameter_diffs)
	return _diff_to_similarity_score(max_diff)

func _calculate_parameter_differences(target: WaveformDrawer) -> Array[float]:
	"""
	Calculate normalized differences for each tunable parameter.
	Each difference is normalized to [0.0, 1.0] range based on parameter's max value.
	"""
	var diffs: Array[float] = []
	diffs.append(_normalize_diff(frequency, target.frequency, 10.0))  # frequency max = 10.0
	diffs.append(_normalize_diff(amplitude, target.amplitude, 1.0))   # amplitude max = 1.0
	diffs.append(_normalize_diff(fm_strength, target.fm_strength, 1.0))
	diffs.append(_normalize_diff(fm_rate, target.fm_rate, 1.0))
	diffs.append(_normalize_diff(am_strength, target.am_strength, 1.0))
	diffs.append(_normalize_diff(am_rate, target.am_rate, 1.0))
	return diffs

func _normalize_diff(current: float, target: float, max_value: float) -> float:
	"""Normalize the difference between two values to [0.0, 1.0] range"""
	return abs(current - target) / max_value

func _get_worst_parameter_difference(diffs: Array[float]) -> float:
	"""
	Get the maximum difference across all parameters.
	Radio-tuning behavior: if ANY dial is off, signal quality degrades.
	"""
	var max_diff = 0.0
	for diff in diffs:
		if diff > max_diff:
			max_diff = diff
	return max_diff

func _diff_to_similarity_score(diff: float) -> float:
	"""
	Convert a difference value to a similarity score using cubic curve.

	Applies cubic curve to the similarity (not the penalty), creating aggressive dropoff:
	- Small errors (0-15%): Minimal penalty, encourages exploration
	- Moderate errors (15-40%): Rapid dropoff, clear feedback that tuning is needed
	- Large errors (40%+): Severe penalty, signal quality is extremely poor

	Examples:
	  10% off → ~72.9% similarity
	  25% off → ~42.2% similarity
	  50% off → ~12.5% similarity (your current test case)
	  75% off → ~1.6% similarity
	  90% off → ~0.1% similarity
	  100% off → 0% similarity
	"""
	var clamped_diff = clamp(diff, 0.0, 1.0)
	var similarity = 1.0 - clamped_diff
	return similarity * similarity * similarity  # similarity³

# === UI Update Logic (Extract to UIService later) ===

func _update_similarity_ui(similarity: float) -> void:
	"""Update the similarity progress bar and color"""
	if _similarity_bar:
		_similarity_bar.value = similarity
		_similarity_bar.modulate = score_to_color(similarity)

	_computed_similarity_score = similarity
	EventBus.pub_signal_similarty_score_changed(similarity)

func _update_signal_lock_state(similarity: float) -> void:
	"""
	Determine if signal can be locked based on similarity threshold.
	Threshold: 0.95 = 95% match required (allows 5% tolerance per parameter)
	"""
	const LOCK_THRESHOLD = 0.95
	_can_lock_signal = similarity >= LOCK_THRESHOLD

func _toggle_button() -> void:
	"""Update lock button state: enabled when signal is locked, disabled otherwise"""
	var should_disable = !_can_lock_signal  # Invert: can_lock=true means enable button (disabled=false)
	if should_disable != _lock_button.disabled:
		_lock_button.disabled = should_disable

## Reset waveform to default parameters (used when loading new puzzle)
func reset_to_defaults() -> void:
	frequency = 5.0
	amplitude = 0.5
	fm_strength = 0.0
	fm_rate = 0.0
	am_strength = 0.0
	am_rate = 0.0
	phase = 0.0
	scroll_speed = 1.0
	queue_redraw()

## Get current lock state (for PuzzleManager)
func can_lock_signal() -> bool:
	return _can_lock_signal

# === UI Helpers ===

func score_to_color(score: float) -> Color:
	score = clamp(score, 0.0, 1.0)

	if score < 0.5:
		# Red to Yellow
		var t = score * 2.0  # 0.0 → 1.0
		return Color(1.0, t, 0.0)  # Red → Yellow
	else:
		# Yellow to Green
		var t = (score - 0.5) * 2.0  # 0.0 → 1.0
		return Color(1.0 - t, 1.0, 0.0)  # Yellow → Green

# === Input Handlers (Extract to InputController later) ===

func _on_scroll_speed_value_changed(value: float) -> void:
	if is_current and value != scroll_speed:
		scroll_speed = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_phase_shift_value_changed(value: float) -> void:
	if is_current and value != phase:
		phase = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_base_frequency_value_changed(value: float) -> void:
	if is_current and value != frequency:
		frequency = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_fm_strength_value_changed(value: float) -> void:
	if is_current and value != fm_strength:
		fm_strength = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_fm_rate_value_changed(value: float) -> void:
	if is_current and value != fm_rate:
		fm_rate = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_base_amplitude_value_changed(value: float) -> void:
	if is_current and value != amplitude:
		amplitude = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_am_strength_value_changed(value: float) -> void:
	if is_current and value != am_strength:
		am_strength = value
		queue_redraw()
		EventBus.pub_play_dial_click()

func _on_am_rate_value_changed(value: float) -> void:
	if is_current and value != am_rate:
		am_rate = value
		queue_redraw()
		EventBus.pub_play_dial_click()
