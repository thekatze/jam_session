extends Control


func _on_bread_player_finished(player_id):
	$"UI/WinPanel/HBoxContainer/PlayerId Text".text = str(player_id + 1)
	$UI/WinPanel.visible = true
	Engine.time_scale = 0
