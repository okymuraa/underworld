class_name Pickup
extends Area2D

## Objeto coleccionable que flota en el mundo y se recoge automáticamente al acercarse

@export var item_data: ItemData
@export var amount: int = 1

var _target_player: Node2D = null
var _collecting: bool = false
var _initial_y: float = 0.0
var _time_passed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

static func spawn(parent: Node, spawn_pos: Vector2, item: ItemData, count: int = 1) -> Pickup:
	var scene = load("res://scenes/objects/pickups/pickup.tscn") as PackedScene
	if not scene:
		return null
	var inst = scene.instantiate() as Pickup
	inst.item_data = item
	inst.amount = count
	inst.global_position = spawn_pos
	parent.add_child(inst)
	# Pequeño impulso inicial aleatorio para que se disperse al caer
	var spread = Vector2(randf_range(-16, 16), randf_range(-12, 12))
	var tween = inst.create_tween()
	tween.tween_property(inst, "position", inst.position + spread, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return inst

func _ready() -> void:
	_initial_y = position.y
	_update_visuals()
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _update_visuals() -> void:
	if item_data and item_data.icon:
		if sprite:
			sprite.texture = item_data.icon
			sprite.visible = true
	else:
		if sprite:
			sprite.visible = false
		queue_redraw()

func _draw() -> void:
	# Figura geométrica representativa si aún no hay arte asignado
	if item_data and (not item_data.icon):
		var col = item_data.placeholder_color
		# Pequeña sombra en el suelo
		draw_circle(Vector2(0, 8), 6, Color(0, 0, 0, 0.3))
		# Rombo representativo del recurso/item
		var points = PackedVector2Array([
			Vector2(0, -7),
			Vector2(7, 0),
			Vector2(0, 7),
			Vector2(-7, 0)
		])
		draw_colored_polygon(points, col)
		draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE.darkened(0.2), 1.0)
		
		# Símbolo
		if item_data.placeholder_symbol != "":
			var font = ThemeDB.fallback_font
			draw_string(font, Vector2(-3, 3), item_data.placeholder_symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.WHITE)

func _process(delta: float) -> void:
	if _collecting and is_instance_valid(_target_player):
		# Volar hacia el jugador suavemente
		global_position = global_position.move_toward(_target_player.global_position, 350.0 * delta)
		if global_position.distance_to(_target_player.global_position) < 12.0:
			_collect()
	else:
		# Flotación suave idle
		_time_passed += delta * 4.0
		position.y = _initial_y + sin(_time_passed) * 2.5

func _on_body_entered(body: Node2D) -> void:
	if _collecting:
		return
	if body.is_in_group("player") or body.name.to_lower() == "player":
		_target_player = body
		_collecting = true

func _collect() -> void:
	if item_data and Engine.has_singleton("InventoryManager") or get_node_or_null("/root/InventoryManager"):
		var mgr = get_node("/root/InventoryManager")
		var remainder = mgr.add_item(item_data, amount)
		if remainder == 0:
			queue_free()
		else:
			amount = remainder
			_collecting = false
	else:
		queue_free()
