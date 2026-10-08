extends Node

## Gestor de inventario y barra de acceso rápido (Hotbar)
## Registrado como Autoload ("InventoryManager")

signal inventory_updated
signal slot_selected(index: int, item: ItemData)
signal item_collected(item: ItemData, amount: int)

const HOTBAR_SIZE: int = 9

# Cada entrada es: {"item": ItemData, "amount": int}
var slots: Array[Dictionary] = []
var selected_slot: int = 0:
	set(val):
		var old = selected_slot
		selected_slot = clampi(val, 0, HOTBAR_SIZE - 1)
		if old != selected_slot or slots.is_empty():
			slot_selected.emit(selected_slot, get_selected_item())

func _ready() -> void:
	_init_slots()
	_give_starter_tools()

func _init_slots() -> void:
	slots.clear()
	for i in range(HOTBAR_SIZE):
		slots.append({"item": null, "amount": 0})

func _give_starter_tools() -> void:
	# Cargar herramientas iniciales para que el jugador pueda probar de inmediato
	var axe = load("res://resources/items/axe.tres") as ItemData
	var pickaxe = load("res://resources/items/pickaxe.tres") as ItemData
	var seed_item = load("res://resources/items/lumina_seed.tres") as ItemData
	if axe:
		add_item(axe, 1)
	if pickaxe:
		add_item(pickaxe, 1)
	if seed_item:
		add_item(seed_item, 3)
	selected_slot = 0

func _unhandled_input(event: InputEvent) -> void:
	# Selección de slots con teclas 1-9
	for i in range(HOTBAR_SIZE):
		var action_name = "hotbar_" + str(i + 1)
		if event.is_action_pressed(action_name):
			selected_slot = i
			get_viewport().set_input_as_handled()
			return

	# Rueda del ratón para ciclar la barra rápida
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_slot = (selected_slot - 1 + HOTBAR_SIZE) % HOTBAR_SIZE
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_slot = (selected_slot + 1) % HOTBAR_SIZE
			get_viewport().set_input_as_handled()

## Agrega un item al inventario. Retorna la cantidad sobrante que no cupo (0 si cupo todo).
func add_item(item: ItemData, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount

	var remaining = amount

	# 1. Intentar apilar en slots existentes que tengan el mismo item
	if item.max_stack > 1:
		for i in range(HOTBAR_SIZE):
			var slot = slots[i]
			if slot["item"] != null and slot["item"].id == item.id:
				var space = item.max_stack - slot["amount"]
				if space > 0:
					var to_add = mini(space, remaining)
					slot["amount"] += to_add
					remaining -= to_add
					if remaining == 0:
						break

	# 2. Si sobra, buscar primer slot vacío
	if remaining > 0:
		for i in range(HOTBAR_SIZE):
			var slot = slots[i]
			if slot["item"] == null:
				var to_add = mini(item.max_stack, remaining)
				slot["item"] = item
				slot["amount"] = to_add
				remaining -= to_add
				if remaining == 0:
					break

	inventory_updated.emit()
	item_collected.emit(item, amount - remaining)
	slot_selected.emit(selected_slot, get_selected_item())
	return remaining

## Remueve cierta cantidad de un item del inventario
func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or not has_item(item.id, amount):
		return false

	var remaining = amount
	for i in range(HOTBAR_SIZE):
		var slot = slots[i]
		if slot["item"] != null and slot["item"].id == item.id:
			var to_take = mini(slot["amount"], remaining)
			slot["amount"] -= to_take
			remaining -= to_take
			if slot["amount"] <= 0:
				slot["item"] = null
				slot["amount"] = 0
			if remaining <= 0:
				break

	inventory_updated.emit()
	slot_selected.emit(selected_slot, get_selected_item())
	return true

## Comprueba si el jugador tiene suficiente cantidad de un item
func has_item(item_id: String, amount: int = 1) -> bool:
	var total = 0
	for slot in slots:
		if slot["item"] != null and slot["item"].id == item_id:
			total += slot["amount"]
			if total >= amount:
				return true
	return false

func get_item_at(index: int) -> ItemData:
	if index >= 0 and index < HOTBAR_SIZE:
		return slots[index]["item"]
	return null

func get_amount_at(index: int) -> int:
	if index >= 0 and index < HOTBAR_SIZE:
		return slots[index]["amount"]
	return 0

func get_selected_item() -> ItemData:
	return get_item_at(selected_slot)
