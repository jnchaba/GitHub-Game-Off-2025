extends Control

@onready var tutorial_text = $PanelContainer/VBoxContainer/TutorialText
@onready var continue_button = $PanelContainer/VBoxContainer/ContinueButton

func _init() -> void:
	_connect_to_event_bus()

func _ready() -> void:
	visible = false

func _connect_to_event_bus() -> void:
	EventBus.show_tutorial.connect(_on_show_tutorial)

func _on_show_tutorial(incoming_text: String) -> void:
	print("_on_show_tutorial fired")
	if not tutorial_text:
		await self.ready
	visible = true
	tutorial_text.text = incoming_text

func _on_continue_button_pressed() -> void:
	EventBus.pub_tutorial_dismissed()
	visible = false
