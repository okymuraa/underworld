class_name Harvestable
extends Area2D

## Componente para árboles, rocas y recursos que el jugador puede talar/picar y cosechar

signal damaged(current_hp: int, max_hp: int)
signal harvested()
signal respawned()

@export var resource_name: String = "Árbol"
@export var max_health: int = 3
@export_enum("none", "axe", "pickaxe", "any") var required_tool: String = "axe"
@export var drop_item: ItemData
@export var min_drop_count: int = 2
@export var max_drop_count: int = 4
@export var respawn_time: float = 30.0
@export var visual_node: Node2D

var current_health: int
var is_depleted: bool = false
var _initial_visual_pos: Vector2 = Vector2.ZERO
var _initial_visual_scale: Vector2 = Vector2.ONE
var _respawn_timer: SceneTreeTimer = null

func _ready() -> void:
	current_health = max_health
	add_to_group("harvestables")
	add_to_group("persist") # WorldState guarda su estado al cambiar de escena
	input_pickable = true
	if visual_node:
		_initial_visual_pos = visual_node.position
		_initial_visual_scale = visual_node.scale
	else:
		# Si no se asignó visual_node, intentar encontrar un sprite en el padre
		var parent = get_parent()
		if parent:
			var sprite = parent.get_node_or_null("dibujo")
			if not sprite:
				sprite = parent.get_node_or_null("Sprite2D")
			if not sprite:
				sprite = parent.get_node_or_null("AnimatedSprite2D")
			if sprite:
				visual_node = sprite
				_initial_visual_pos = sprite.position
				_initial_visual_scale = sprite.scale

## Intentar golpear el recurso con una herramienta
func hit(tool_type: String, tool_power: int = 1) -> bool:
	if is_depleted:
		return false

	# Verificar si se usa la herramienta adecuada
	var is_valid_tool = (required_tool == "none" or required_tool == "any" or tool_type == required_tool)
	if not is_valid_tool:
		# Pequeño rebote de herramienta incorrecta (sonido sutil / mensaje)
		_shake(2.0, 0.1)
		return false

	current_health -= maxi(1, tool_power)
	_shake(5.0, 0.15)
	damaged.emit(current_health, max_health)

	if current_health <= 0:
		_deplete()
	return true

func _shake(intensity: float, duration: float) -> void:
	if not visual_node:
		return
	var tween = create_tween()
	var offset_left = _initial_visual_pos + Vector2(-intensity, 0)
	var offset_right = _initial_visual_pos + Vector2(intensity, 0)
	tween.tween_property(visual_node, "position", offset_left, duration * 0.25)
	tween.tween_property(visual_node, "position", offset_right, duration * 0.25)
	tween.tween_property(visual_node, "position", _initial_visual_pos, duration * 0.5)

func _deplete() -> void:
	is_depleted = true
	harvested.emit()

	# Generar drops
	if drop_item:
		var count = randi_range(min_drop_count, max_drop_count)
		var spawn_pos = global_position
		Pickup.spawn(get_tree().current_scene, spawn_pos, drop_item, count)

	_hide_depleted(true)

	# Manejar respawn o eliminación definitiva
	if respawn_time > 0:
		_start_respawn_timer(respawn_time)
	else:
		var to_remove: Node = get_parent() if get_parent() else self
		# Recordar que ya no existe, para que no vuelva a aparecer al regresar a la escena
		WorldState.mark_removed(to_remove)
		to_remove.queue_free()

## Oculta el visual y desactiva la colisión del padre (animado al talar, instantáneo al cargar)
func _hide_depleted(animated: bool) -> void:
	if visual_node:
		if animated:
			var tween = create_tween()
			tween.tween_property(visual_node, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(func(): visual_node.visible = false)
		else:
			visual_node.scale = Vector2.ZERO
			visual_node.visible = false

	# Desactivar colisiones del objeto padre si las tiene
	var parent_body = get_parent() as CollisionObject2D
	if parent_body:
		parent_body.set_collision_layer_value(1, false)

func _start_respawn_timer(seconds: float) -> void:
	_respawn_timer = get_tree().create_timer(seconds)
	_respawn_timer.timeout.connect(_respawn)

func _respawn() -> void:
	_respawn_timer = null
	is_depleted = false
	current_health = max_health
	add_to_group("harvestables")
	if visual_node:
		visual_node.visible = true
		visual_node.position = _initial_visual_pos
		var tween = create_tween()
		visual_node.scale = Vector2.ZERO
		tween.tween_property(visual_node, "scale", _initial_visual_scale, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var parent_body = get_parent() as CollisionObject2D
	if parent_body:
		parent_body.set_collision_layer_value(1, true)

	respawned.emit()

## --- Persistencia (usado por WorldState) ---
func save_state() -> Dictionary:
	return {
		"health": current_health,
		"depleted": is_depleted,
		"respawn_left": _respawn_timer.time_left if is_depleted and _respawn_timer else 0.0,
	}

## 'elapsed' = segundos que pasaron fuera de la escena; la cuenta atrás de reaparición sigue corriendo
func load_state(data: Dictionary, elapsed: float) -> void:
	current_health = data.get("health", max_health)
	if not data.get("depleted", false):
		return
	var left: float = data.get("respawn_left", 0.0) - elapsed
	if left > 0.0:
		is_depleted = true
		_hide_depleted(false)
		_start_respawn_timer(left)
	else:
		# Ya reapareció mientras no estabas
		current_health = max_health
