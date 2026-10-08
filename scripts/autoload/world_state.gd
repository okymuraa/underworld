extends Node

## Guarda el estado del mundo de cada escena (árboles talados, cultivos, objetos en el suelo)
## para que no se pierda al entrar y salir de casas o cavernas.
## Registrado como Autoload ("WorldState")
##
## Cualquier nodo en el grupo "persist" que tenga save_state() -> Dictionary y
## load_state(data: Dictionary, elapsed: float) se guarda y restaura automáticamente.
## Se identifica por su ruta dentro de la escena (ej: "plants/Tree1/Harvestable"),
## así que si renombras un nodo en el editor, pierde su estado guardado.
## Los datos son diccionarios simples para poder escribirlos a disco más adelante.

const PERSIST_GROUP := "persist"
const PICKUP_GROUP := "pickups"

## Reloj de juego en segundos (se detiene si el juego está en pausa)
var game_time: float = 0.0

# scene_file_path -> {"time": float, "objects": {ruta: Dictionary}, "removed": Array, "pickups": Array}
var _scenes: Dictionary = {}

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

func _process(delta: float) -> void:
	game_time += delta

## Cambia de escena guardando antes el estado de la actual. Úsalo en lugar de change_scene_to_file
func change_scene(path: String) -> void:
	save_scene(get_tree().current_scene)
	# Diferido: las puertas llaman desde body_entered (callback de física) y ahí
	# Godot no permite quitar nodos con colisión
	get_tree().change_scene_to_file.call_deferred(path)

func save_scene(scene_root: Node) -> void:
	if scene_root == null or scene_root.scene_file_path == "":
		return
	var data := _get_scene_data(scene_root.scene_file_path)
	data["time"] = game_time

	var objects := {}
	for node in get_tree().get_nodes_in_group(PERSIST_GROUP):
		if scene_root.is_ancestor_of(node) and node.has_method("save_state"):
			objects[str(scene_root.get_path_to(node))] = node.save_state()
	data["objects"] = objects

	var pickups := []
	for node in get_tree().get_nodes_in_group(PICKUP_GROUP):
		if scene_root.is_ancestor_of(node) and not node.is_queued_for_deletion() and node.item_data:
			pickups.append({
				"item": node.item_data.resource_path,
				"amount": node.amount,
				"position": node.global_position,
			})
	data["pickups"] = pickups

func restore_scene(scene_root: Node) -> void:
	if scene_root == null or not _scenes.has(scene_root.scene_file_path):
		return
	var data: Dictionary = _scenes[scene_root.scene_file_path]
	var elapsed: float = game_time - data["time"]

	for path in data["removed"]:
		var removed_node = scene_root.get_node_or_null(path)
		if removed_node:
			removed_node.queue_free()

	var objects: Dictionary = data["objects"]
	for node in get_tree().get_nodes_in_group(PERSIST_GROUP):
		if scene_root.is_ancestor_of(node) and node.has_method("load_state"):
			var key := str(scene_root.get_path_to(node))
			if objects.has(key):
				node.load_state(objects[key], elapsed)

	for p in data["pickups"]:
		var item = load(p["item"]) as ItemData
		if item:
			Pickup.spawn(scene_root, p["position"], item, p["amount"], false)

## Marca un nodo como eliminado para siempre (ej: un recurso sin respawn)
func mark_removed(node: Node) -> void:
	var scene_root := _find_scene_root(node)
	if scene_root == null or scene_root.scene_file_path == "":
		return
	var removed: Array = _get_scene_data(scene_root.scene_file_path)["removed"]
	var path := str(scene_root.get_path_to(node))
	if not removed.has(path):
		removed.append(path)

func _on_scene_changed() -> void:
	restore_scene(get_tree().current_scene)

func _get_scene_data(scene_path: String) -> Dictionary:
	if not _scenes.has(scene_path):
		_scenes[scene_path] = {"time": game_time, "objects": {}, "removed": [], "pickups": []}
	return _scenes[scene_path]

func _find_scene_root(node: Node) -> Node:
	var root := get_tree().root
	while node and node.get_parent() != root:
		node = node.get_parent()
	return node
