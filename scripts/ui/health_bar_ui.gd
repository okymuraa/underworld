extends Control

## Barra de vida del jugador (esquina superior izquierda). Escucha a Global.player_health_changed

const COLOR_HIGH := Color(0.35, 0.8, 0.35)
const COLOR_MID := Color(0.95, 0.75, 0.2)
const COLOR_LOW := Color(0.9, 0.2, 0.25)

@onready var bar: ProgressBar = $Panel/Margin/HBox/Bar
@onready var value_label: Label = $Panel/Margin/HBox/Bar/Value

func _ready() -> void:
	Global.player_health_changed.connect(_on_health_changed)
	_on_health_changed(Global.player_health, Global.player_max_health)

func _on_health_changed(current: int, max_health: int) -> void:
	bar.max_value = max_health
	bar.value = current
	value_label.text = "%d / %d" % [current, max_health]

	# Verde > 50 %, amarillo > 25 %, rojo por debajo
	var ratio := float(current) / float(max_health)
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		if ratio > 0.5:
			fill.bg_color = COLOR_HIGH
		elif ratio > 0.25:
			fill.bg_color = COLOR_MID
		else:
			fill.bg_color = COLOR_LOW
