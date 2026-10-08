extends Node

## Script global (Singleton) para guardar variables persistentes entre escenas
## Registra este script en Godot: Proyecto -> Configuración del Proyecto -> Autoload (con el nombre 'Global')

# Almacena la posición donde debe colocarse el jugador al cargar la nueva escena
var next_spawn_position: Vector2 = Vector2.ZERO

# --- Vida del jugador (persiste al cambiar de escena) ---
signal player_health_changed(current: int, max_health: int)

var player_max_health: int = 100:
	set(value):
		player_max_health = maxi(1, value)
		player_health = mini(player_health, player_max_health)
var player_health: int = 100:
	set(value):
		player_health = clampi(value, 0, player_max_health)
		player_health_changed.emit(player_health, player_max_health)
