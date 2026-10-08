class_name CropPlot
extends Node2D

## Gestiona el crecimiento, cuidado y cosecha de una planta

signal crop_planted(crop: CropData)
signal crop_stage_changed(stage: int)
signal crop_harvested()

@export var crop_data: CropData
@export var is_planter_box: bool = true

var current_stage: int = 0
var max_stages: int = 3
var is_mature: bool = false
var _growth_timer: float = 0.0

@onready var plant_sprite: Sprite2D = $PlantSprite
@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	add_to_group("persist") # WorldState guarda su estado al cambiar de escena
	if interactable:
		interactable.interacted.connect(_on_interacted)
	_update_state()

func _process(delta: float) -> void:
	_simulate_growth(delta)

## Avanza el crecimiento como si hubieran pasado 'seconds' segundos
## (cada frame, o de golpe al volver a una escena)
func _simulate_growth(seconds: float) -> void:
	while crop_data != null and not is_mature and seconds > 0.0:
		var needed = crop_data.seconds_per_stage - _growth_timer
		if seconds < needed:
			_growth_timer += seconds
			return
		seconds -= needed
		_growth_timer = 0.0
		_advance_stage()

func _advance_stage() -> void:
	current_stage += 1
	var total_stages = crop_data.growth_stage_textures.size() if not crop_data.growth_stage_textures.is_empty() else max_stages
	if current_stage >= total_stages - 1:
		current_stage = total_stages - 1
		is_mature = true
	_update_state()
	crop_stage_changed.emit(current_stage)

func _update_state() -> void:
	if crop_data == null:
		# Vacío / listo para plantar
		if plant_sprite:
			plant_sprite.visible = false
		if interactable:
			interactable.prompt_message = "Plantar semilla"
	elif is_mature:
		# Listo para cosechar
		if plant_sprite:
			plant_sprite.visible = true
			_apply_stage_texture()
		if interactable:
			interactable.prompt_message = "Cosechar " + crop_data.crop_name
	else:
		# Creciendo
		if plant_sprite:
			plant_sprite.visible = true
			_apply_stage_texture()
		if interactable:
			interactable.prompt_message = crop_data.crop_name + " (Creciendo...)"
	queue_redraw()

func _apply_stage_texture() -> void:
	if crop_data and not crop_data.growth_stage_textures.is_empty():
		if current_stage < crop_data.growth_stage_textures.size():
			plant_sprite.texture = crop_data.growth_stage_textures[current_stage]
			plant_sprite.visible = true
			return
	plant_sprite.visible = false

func _draw() -> void:
	# Figura geométrica representativa mientras no haya sprites
	if crop_data != null and (crop_data.growth_stage_textures.is_empty() or not plant_sprite.texture):
		var col = crop_data.placeholder_color
		var y_off = -10.0
		if current_stage == 0:
			# Fase 1: Pequeño brote verde
			draw_circle(Vector2(0, y_off), 4, col.darkened(0.1))
			draw_line(Vector2(0, 0), Vector2(0, y_off), Color(0.2, 0.6, 0.2), 2.0)
		elif current_stage == 1:
			# Fase 2: Tallo mediano con 2 hojas
			draw_line(Vector2(0, 0), Vector2(0, y_off - 6), Color(0.2, 0.6, 0.2), 2.5)
			draw_circle(Vector2(-4, y_off - 2), 3, col)
			draw_circle(Vector2(4, y_off - 4), 3, col)
		else:
			# Fase 3: Planta adulta florecida / lista para cosechar
			draw_line(Vector2(0, 0), Vector2(0, y_off - 10), Color(0.2, 0.6, 0.2), 3.0)
			draw_circle(Vector2(0, y_off - 12), 7, col) # Flor o fruto maduro
			draw_circle(Vector2(0, y_off - 12), 3, Color.WHITE) # Centro brillante

func _on_interacted(player: Node2D) -> void:
	if is_mature:
		_harvest()
	elif crop_data == null:
		_try_plant()

func _try_plant() -> void:
	# Comprobar si el jugador tiene una semilla equipada o en inventario
	if not (Engine.has_singleton("InventoryManager") or get_node_or_null("/root/InventoryManager")):
		return
	var mgr = get_node("/root/InventoryManager")
	var equipped = mgr.get_selected_item()

	var seed_to_use: ItemData = null
	if equipped != null and equipped.item_type == "seed":
		seed_to_use = equipped
	else:
		# Buscar si tiene alguna semilla en cualquier slot
		for i in range(mgr.HOTBAR_SIZE):
			var it = mgr.get_item_at(i)
			if it != null and it.item_type == "seed":
				seed_to_use = it
				break

	if seed_to_use != null:
		# Cargar el CropData asociado a esta semilla
		var crop_res = _find_crop_for_seed(seed_to_use)
		if crop_res:
			mgr.remove_item(seed_to_use, 1)
			plant(crop_res)

func plant(data: CropData) -> void:
	crop_data = data
	current_stage = 0
	is_mature = false
	_growth_timer = 0.0
	_update_state()
	crop_planted.emit(data)

func _harvest() -> void:
	if not is_mature or crop_data == null:
		return

	# Dropear cosecha
	if crop_data.harvest_item:
		var count = randi_range(crop_data.min_harvest_count, crop_data.max_harvest_count)
		Pickup.spawn(get_tree().current_scene, global_position, crop_data.harvest_item, count)

	# Probabilidad de dropear semilla extra
	if crop_data.seed_item and randf() <= crop_data.extra_seed_chance:
		Pickup.spawn(get_tree().current_scene, global_position, crop_data.seed_item, 1)

	crop_harvested.emit()

	# Si es silvestre (o perenne), vuelve a crecer; si es caja de cultivo, queda vacía
	if crop_data.is_perennial_wild or not is_planter_box:
		is_mature = false
		current_stage = 0
		_growth_timer = 0.0
		_update_state()
	else:
		crop_data = null
		is_mature = false
		current_stage = 0
		_growth_timer = 0.0
		_update_state()

func _find_crop_for_seed(seed_item: ItemData) -> CropData:
	# Buscar el archivo de cultivo correspondiente
	var test_path = "res://resources/crops/" + seed_item.id.replace("_seed", "") + "_crop.tres"
	if ResourceLoader.exists(test_path):
		return load(test_path) as CropData
	return null

## --- Persistencia (usado por WorldState) ---
func save_state() -> Dictionary:
	return {
		"crop": crop_data.resource_path if crop_data else "",
		"stage": current_stage,
		"mature": is_mature,
		"growth_timer": _growth_timer,
	}

## 'elapsed' = segundos que pasaron fuera de la escena; la planta sigue creciendo en ese tiempo
func load_state(data: Dictionary, elapsed: float) -> void:
	var path: String = data.get("crop", "")
	crop_data = load(path) as CropData if path != "" else null
	current_stage = data.get("stage", 0)
	is_mature = data.get("mature", false)
	_growth_timer = data.get("growth_timer", 0.0)
	_simulate_growth(elapsed)
	_update_state()
