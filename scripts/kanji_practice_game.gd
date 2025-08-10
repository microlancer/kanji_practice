extends Control


func _on_tab_bar_tab_changed(tab: int) -> void:
	for i in $TabBar.get_children():
		if i.get_index() != tab:
			i.visible = false
		else:
			i.visible = true
