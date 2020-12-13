extends MenuButton


func _ready() -> void:
	get_popup().connect("id_pressed", self, "on_PopupMenu_id_pressed")
	
	get_popup().set_hide_on_checkable_item_selection(false)

func get_selected() -> Array:
	var selected = []
	for i in range(get_popup().get_item_count()):
		if get_popup().is_item_checked(i):
			selected.append(get_popup().get_item_text(i))
	return selected

func set_groups(groups: Array) -> void:
	get_popup().clear()
	for group_title in groups:
		get_popup().add_check_item(group_title)

func on_PopupMenu_id_pressed(idx: int) -> void:
	var new_checked_state = not get_popup().is_item_checked(idx)
	get_popup().set_item_checked(idx, new_checked_state)

func _get_groups() -> Array:
	var groups = []
	for i in range(len(get_popup().get_item_count())):
		groups.append(get_popup().get_item_text(i))
	return groups
