class_name Door
extends Area2D

## Portal / Puerta para cambiar de escena y transportar al jugador

@export_file("*.tscn") var new_scene_path: String
@export var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Asegurar conexión si no está conectada en la escena
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		change_scene()

func change_scene() -> void:
	if new_scene_path != "":
		if spawn_position != Vector2.ZERO:
			if get_node_or_null("/root/Global"):
				get_node("/root/Global").next_spawn_position = spawn_position
		# Guarda el estado del mundo actual antes de salir
		WorldState.change_scene(new_scene_path)
	else:
		print("Advertencia: new_scene_path no tiene asignada una escena .tscn")
