extends Area2D

var jamLevelPercentage: Array[int] = [0,0,0,0]
var jamStats: Array[Node]

signal playerFinished(player_id)

# Called when the node enters the scene tree for the first time.
func _ready():
	jamStats = [$Jam/Jam_0, $Jam/Jam_1, $Jam/Jam_2, $Jam/Jam_3]
	for i in range(4):
		_setJamLevel(i,0)	

func _setJamLevel(playerId: int, jamLevel: int):
	jamLevelPercentage[playerId] = jamLevel
	jamStats[playerId].position.y = 64 - 64*min(jamLevelPercentage[playerId]/100.0, 1)
	if jamLevelPercentage[playerId] >= 100:
		playerFinished.emit(playerId)

func _on_body_entered(body):
	if body.is_in_group("player"):
		_setJamLevel(body.player_id, jamLevelPercentage[body.player_id] + body.remaining_jam_uses * 10)
		body.remaining_jam_uses = 0
		body.update_jam_level()	
