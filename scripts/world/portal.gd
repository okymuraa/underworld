extends Area2D

## La escena a la que quieres ir (ej: "res://interior_casa.tscn")
## Puedes arrastrar el archivo de la escena directamente a esta propiedad en el Inspector
@export_file("*.tscn") var target_scene: String

## La posición en la que quieres que aparezca el jugador en la nueva escena (opcional)
@export var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Conectar la señal body_entered para detectar cuando el personaje pisa la puerta
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificar si lo que entró al área es el personaje jugador
	if body is CharacterBody2D:
		if target_scene != "":
			# Si especificamos una posición de spawn, guardamos el dato en una variable global (Singleton)
			if spawn_position != Vector2.ZERO and HasGlobalManager():
				GetGlobalManager().next_spawn_position = spawn_position
			
			# Cambiar a la escena destino
			WorldState.change_scene(target_scene)
		else:
			print("Advertencia: No has configurado la escena de destino (target_scene) en este portal.")

# Funciones de utilidad para verificar si existe un gestor global
func HasGlobalManager() -> bool:
	return Engine.has_singleton("Global") or get_tree().root.has_node("Global")

func GetGlobalManager() -> Node:
	return get_tree().root.get_node("Global")
