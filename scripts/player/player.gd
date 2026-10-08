extends CharacterBody2D

signal died

## Velocidad de movimiento del personaje en píxeles por segundo
@export var speed: float = 150.0

## Nombres de tus animaciones en el AnimatedSprite2D
@export var anim_down: String = "walk"
@export var anim_up: String = "walk_back"
@export var anim_side: String = "walk_side"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
## Alcance de las herramientas: edita el CollisionShape2D de "ToolRange" en player.tscn
@onready var tool_range: Area2D = $ToolRange

var _last_facing_dir: Vector2 = Vector2.DOWN
var _is_acting: bool = false

func _ready() -> void:
	add_to_group("player")

	# Si hay una posición de aparición guardada globalmente, nos movemos a ella
	if get_node_or_null("/root/Global") and get_node("/root/Global").next_spawn_position != Vector2.ZERO:
		global_position = get_node("/root/Global").next_spawn_position
		get_node("/root/Global").next_spawn_position = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")

	if input_dir != Vector2.ZERO:
		var move_dir: Vector2 = input_dir.normalized()
		velocity = move_dir * speed
		_last_facing_dir = move_dir

		# Selección automática de animación según la dirección
		if animated_sprite and not _is_acting:
			if abs(input_dir.y) > abs(input_dir.x):
				if input_dir.y < 0:
					_play_anim(anim_up, false)
				else:
					_play_anim(anim_down, false)
			else:
				if input_dir.x < 0:
					_play_anim(anim_side, true)
				else:
					_play_anim(anim_side, false)
	else:
		velocity = Vector2.ZERO
		if animated_sprite and not _is_acting:
			animated_sprite.stop()
			animated_sprite.frame = 0

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# Interactuar con objeto cercano (tecla E)
	if event.is_action_pressed("interact"):
		_try_interact()

	# Usar herramienta / golpear (clic izquierdo)
	if event.is_action_pressed("use_tool"):
		_use_equipped_tool()

func _play_anim(anim_name: String, flip: bool) -> void:
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
	animated_sprite.flip_h = flip

## Acción de usar la herramienta equipada hacia la posición del ratón
func _use_equipped_tool() -> void:
	# Esperar a que termine el golpe anterior (evita golpear sin animación al spamear clic)
	if _is_acting:
		return
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	# Obtener item actualmente seleccionado en el inventario
	var tool_type = "none"
	var tool_power = 1
	var tool_color = Color(1.0, 0.9, 0.4)

	if get_node_or_null("/root/InventoryManager"):
		var mgr = get_node("/root/InventoryManager")
		var item = mgr.get_selected_item()
		if item:
			tool_type = item.tool_type
			tool_power = item.tool_power
			tool_color = item.placeholder_color

	# Efecto visual de golpe / acción (inclinación sutil)
	_animate_tool_swing(to_mouse.normalized(), tool_color)

	# Buscar Harvestable dentro del área de alcance, priorizando el más cercano al cursor
	var target_harvestable = _find_target_harvestable(mouse_pos)
	if target_harvestable:
		target_harvestable.hit(tool_type, tool_power)

func _find_target_harvestable(target_pos: Vector2) -> Harvestable:
	# Solo cuentan los recursos cuya área toca el ToolRange del jugador
	var nearest: Harvestable = null
	var min_d = INF
	for area in tool_range.get_overlapping_areas():
		if area is Harvestable and not area.is_depleted:
			var d = target_pos.distance_to(area.global_position)
			if d < min_d:
				min_d = d
				nearest = area

	return nearest

func _animate_tool_swing(dir: Vector2, color: Color) -> void:
	if _is_acting or not animated_sprite:
		return
	_is_acting = true

	# Efecto de golpe visual (estiramiento y retorno)
	var original_pos = animated_sprite.position
	var punch_offset = dir * 6.0
	var tween = create_tween()
	tween.tween_property(animated_sprite, "position", original_pos + punch_offset, 0.08)
	tween.tween_property(animated_sprite, "position", original_pos, 0.1)
	tween.tween_callback(func(): _is_acting = false)

	# Crear un sutil efecto de arco / destello representativo en la dirección del golpe
	_spawn_swing_effect(global_position + dir * 18.0, dir.angle(), color)

func _spawn_swing_effect(spawn_pos: Vector2, angle: float, col: Color) -> void:
	var effect = Node2D.new()
	effect.global_position = spawn_pos
	effect.rotation = angle
	get_parent().add_child(effect)

	# Dibujo representativo del corte/golpe
	effect.draw.connect(func():
		var points = PackedVector2Array([
			Vector2(-4, -10),
			Vector2(8, 0),
			Vector2(-4, 10)
		])
		effect.draw_polyline(points, col, 2.5)
	)
	effect.queue_redraw()

	var tw = effect.create_tween()
	tw.tween_property(effect, "scale", Vector2(1.4, 1.4), 0.15)
	tw.parallel().tween_property(effect, "modulate:a", 0.0, 0.15)
	tw.tween_callback(effect.queue_free)

func _try_interact() -> void:
	# Buscar el interactable más cercano cuyo área nos tenga dentro (el que muestra "[E] ...")
	var nearest: Interactable = null
	var min_dist: float = 99999.0

	var areas = get_tree().get_nodes_in_group("interactables")
	for node in areas:
		if node is Interactable and node.is_active and node.player_in_range == self:
			var d = global_position.distance_to(node.global_position)
			if d < min_dist:
				min_dist = d
				nearest = node

	if nearest:
		nearest.interact(self)

## Resta vida al jugador (la vida vive en Global para conservarse entre escenas)
func take_damage(amount: int) -> void:
	if amount <= 0 or Global.player_health <= 0:
		return
	Global.player_health -= amount
	_flash_damage()
	if Global.player_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return
	Global.player_health += amount

func _flash_damage() -> void:
	if not animated_sprite:
		return
	var tw = create_tween()
	animated_sprite.modulate = Color(1.0, 0.35, 0.35)
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)
