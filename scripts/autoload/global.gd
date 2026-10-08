extends Node

## Script global (Singleton) para guardar variables persistentes entre escenas
## Registra este script en Godot: Proyecto -> Configuración del Proyecto -> Autoload (con el nombre 'Global')

# Almacena la posición donde debe colocarse el jugador al cargar la nueva escena
var next_spawn_position: Vector2 = Vector2.ZERO
