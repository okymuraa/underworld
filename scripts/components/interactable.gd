class_name Interactable
extends Area2D

## Componente para cualquier objeto con el que el jugador pueda interactuar (presionando 'E')

signal interacted(player: Node2D)

var _label: Label = null

@export var prompt_message: String = "Interactuar":
	set(value):
		prompt_message = value
		# Refrescar el texto aunque el jugador ya esté dentro del área
		if _label:
			_label.text = "[E] " + prompt_message
@export var is_active: bool = true

var player_in_range: Node2D = null

func _ready() -> void:
	# Configurar colisiones para interactuar
	add_to_group("interactables")
	monitorable = true
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_prompt_ui()

func _setup_prompt_ui() -> void:
	_label = Label.new()
	_label.text = "[E] " + prompt_message
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-50, -45)
	_label.custom_minimum_size = Vector2(100, 20)
	_label.visible = false
	_label.z_index = 50
	
	# Estilo sutil de texto con sombra / borde legible
	_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body.is_in_group("player") or body.name.to_lower() == "player":
		player_in_range = body
		if _label:
			_label.text = "[E] " + prompt_message
			_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		if _label:
			_label.visible = false

func interact(player: Node2D) -> void:
	if not is_active:
		return
	interacted.emit(player)
