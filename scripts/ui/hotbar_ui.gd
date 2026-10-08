extends Control

## UI para la barra de acceso rápido (Hotbar de 9 ranuras)

@onready var slots_container: HBoxContainer = $CenterContainer/VBoxContainer/SlotsContainer
@onready var item_name_label: Label = $CenterContainer/VBoxContainer/ItemNameLabel

var slot_panels: Array[PanelContainer] = []

func _ready() -> void:
	_create_slots()
	if Engine.has_singleton("InventoryManager") or get_node_or_null("/root/InventoryManager"):
		var mgr = get_node("/root/InventoryManager")
		mgr.inventory_updated.connect(_update_ui)
		mgr.slot_selected.connect(_on_slot_selected)
		_update_ui()
		_update_selected_highlight(mgr.selected_slot)

func _create_slots() -> void:
	# Limpiar hijos previos si los hay
	for child in slots_container.get_children():
		child.queue_free()
	slot_panels.clear()

	for i in range(9):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(44, 44)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if get_node_or_null("/root/InventoryManager"):
					get_node("/root/InventoryManager").selected_slot = i
		)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.16, 0.85)
		style.border_color = Color(0.35, 0.35, 0.45, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)

		# Contenedor interno
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)

		# Icono / Representación
		var center = CenterContainer.new()
		margin.add_child(center)

		var icon_rect = TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.custom_minimum_size = Vector2(32, 32) # 2x los íconos de 16px
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # pixel art nítido
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		center.add_child(icon_rect)

		var placeholder_rect = ColorRect.new()
		placeholder_rect.name = "Placeholder"
		placeholder_rect.custom_minimum_size = Vector2(20, 20)
		placeholder_rect.visible = false
		center.add_child(placeholder_rect)

		var placeholder_sym = Label.new()
		placeholder_sym.name = "PlaceholderSymbol"
		placeholder_sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder_sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder_sym.add_theme_font_size_override("font_size", 11)
		center.add_child(placeholder_sym)

		# Número de tecla (1-9) en la esquina superior izquierda
		var num_label = Label.new()
		num_label.text = str(i + 1)
		num_label.add_theme_font_size_override("font_size", 9)
		num_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.7))
		margin.add_child(num_label)

		# Cantidad (x2, etc.) en la esquina inferior derecha
		var qty_label = Label.new()
		qty_label.name = "Qty"
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_label.add_theme_font_size_override("font_size", 10)
		qty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		qty_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		qty_label.add_theme_constant_override("shadow_offset_x", 1)
		qty_label.add_theme_constant_override("shadow_offset_y", 1)
		margin.add_child(qty_label)

		slots_container.add_child(panel)
		slot_panels.append(panel)

func _update_ui() -> void:
	if not get_node_or_null("/root/InventoryManager"):
		return
	var mgr = get_node("/root/InventoryManager")

	for i in range(slot_panels.size()):
		var panel = slot_panels[i]
		var item = mgr.get_item_at(i)
		var amount = mgr.get_amount_at(i)

		var icon_rect = panel.find_child("Icon", true, false) as TextureRect
		var placeholder = panel.find_child("Placeholder", true, false) as ColorRect
		var symbol_lbl = panel.find_child("PlaceholderSymbol", true, false) as Label
		var qty_lbl = panel.find_child("Qty", true, false) as Label

		if item != null and amount > 0:
			if item.icon != null:
				icon_rect.texture = item.icon
				icon_rect.visible = true
				placeholder.visible = false
				symbol_lbl.visible = false
			else:
				# Mostrar figura representativa coloreada
				icon_rect.visible = false
				placeholder.visible = true
				placeholder.color = item.placeholder_color
				symbol_lbl.visible = true
				symbol_lbl.text = item.placeholder_symbol

			if amount > 1:
				qty_lbl.text = str(amount)
				qty_lbl.visible = true
			else:
				qty_lbl.visible = false
		else:
			icon_rect.visible = false
			placeholder.visible = false
			symbol_lbl.visible = false
			qty_lbl.visible = false

	_update_selected_info(mgr.selected_slot)

func _on_slot_selected(slot_index: int, _item: ItemData) -> void:
	_update_selected_highlight(slot_index)
	_update_selected_info(slot_index)

func _update_selected_highlight(active_idx: int) -> void:
	for i in range(slot_panels.size()):
		var panel = slot_panels[i]
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			if i == active_idx:
				style.border_color = Color(1.0, 0.85, 0.2, 1.0) # Dorado / Selección
				style.set_border_width_all(3)
			else:
				style.border_color = Color(0.35, 0.35, 0.45, 0.9)
				style.set_border_width_all(2)

func _update_selected_info(idx: int) -> void:
	if not get_node_or_null("/root/InventoryManager"):
		return
	var mgr = get_node("/root/InventoryManager")
	var item = mgr.get_item_at(idx)
	if item != null:
		var txt = item.name
		var amt = mgr.get_amount_at(idx)
		if amt > 1:
			txt += " (" + str(amt) + ")"
		item_name_label.text = txt
		item_name_label.visible = true
	else:
		item_name_label.visible = false
