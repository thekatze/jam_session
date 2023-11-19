extends CharacterBody2D

@export var player_id : int = 0
@export var trap_scene : PackedScene
@export var player_colors : PackedColorArray

const SPEED = 400.0
const JUMP_VELOCITY = -460.0
const MAX_JAM_USES = 5

var stuck_counter = 0
var sticky_trap
var orientation = 1 # 1 => looking right; -1 => looking left;
var is_in_air = false
var is_in_jam = true
var remaining_jam_uses = MAX_JAM_USES

const GROUND_SPEED = 360.0
const AIR_SPEED = 280.0
const TILE_HEIGHT = 24
const JUMP_HEIGHT_IN_TILES = 4
const JUMP_HEIGHT = -TILE_HEIGHT * JUMP_HEIGHT_IN_TILES
const JUMP_DISTANCE_TO_PEAK_IN_TILES = 3
const JUMP_DISTANCE_TO_PEAK = TILE_HEIGHT * JUMP_DISTANCE_TO_PEAK_IN_TILES
const JUMP_PEAK_DURATION = JUMP_DISTANCE_TO_PEAK / AIR_SPEED

const DOWNWARD_GRAVITY_GRAVITY = 1.4

# jump calculation according to https://www.youtube.com/watch?v=hG9SzQxaCm8
var gravity = (-2 * JUMP_HEIGHT) / (JUMP_PEAK_DURATION * JUMP_PEAK_DURATION)

var jump_velocity = -gravity * JUMP_PEAK_DURATION

func set_stuck(trap):
	if not is_stuck():
		$SfxStuck.play()
		sticky_trap = trap
		velocity.x = 0

func is_stuck():
	return is_instance_valid(sticky_trap) and sticky_trap.is_sticky()

func _ready():
	# set player color
	var gradient : GradientTexture2D = $Sprite2D.texture
	gradient = gradient.duplicate(true)
	gradient.gradient.colors[1] = player_colors[player_id]
	$Sprite2D.texture = gradient
	
func can_place_trap():
	return is_on_floor() \
		and not is_in_jam \
		and remaining_jam_uses > 0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		var downward_gravity_factor = 1 if velocity.y < 0 else DOWNWARD_GRAVITY_GRAVITY
		velocity.y += gravity * downward_gravity_factor * delta
		is_in_air = true
	else:
		if is_in_air and not is_in_jam:
			# only once on land
			$SfxLand.play()
		is_in_air = false
		
	if Input.is_action_just_pressed("attack_%s" % player_id) and can_place_trap():
		# try to place trap
		var original_placement_position = $TrapPlacementPosition.position
		var timeout = 1000
		# find closest point where ground is detected at both ends of the placed trap
		while(timeout > 0 and not ($TrapPlacementPosition/TrapPlacementRaycastLeft.is_colliding() \
		and $TrapPlacementPosition/TrapPlacementRaycastRight.is_colliding())):
			$TrapPlacementPosition.position.x -= sign(original_placement_position.x)
			$TrapPlacementPosition/TrapPlacementRaycastLeft.force_update_transform()
			$TrapPlacementPosition/TrapPlacementRaycastLeft.force_raycast_update()
			$TrapPlacementPosition/TrapPlacementRaycastRight.force_update_transform()
			$TrapPlacementPosition/TrapPlacementRaycastRight.force_raycast_update()
			timeout -= 1
		$TrapPlacementPosition/TrapOverlapCheckArea.force_update_transform()
		var has_other_traps = $TrapPlacementPosition/TrapOverlapCheckArea.has_overlapping_areas()
		# only if actual free area was found
		if timeout > 0 and not has_other_traps:
			var trap = trap_scene.instantiate()
			trap.belongs_to = self.player_id
			trap.color = player_colors[player_id]
			trap.position = self.position + $TrapPlacementPosition.position
			get_tree().current_scene.add_child(trap)
			remaining_jam_uses -= 1
		$TrapPlacementPosition.position = original_placement_position

	if not is_stuck():
		# Handle Jump
		if Input.is_action_just_pressed("jump_%s" % player_id) and is_on_floor():
			velocity.y = jump_velocity
			$SfxJump.play()

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("move_left_%s" % player_id, "move_right_%s" % player_id)
		# Might be nice to interpolate between ground speed and air speed
		# However we must be careful to avoid "ice" physics doing that 
		var speed = GROUND_SPEED if is_on_floor() else AIR_SPEED
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
		
		# set orientation
		if abs(velocity.x) > 0.01:
			if velocity.x > 0:
				orientation = 1
				$Sprite2D.flip_h = false
				$TrapPlacementPosition.position.x = abs($TrapPlacementPosition.position.x)
			else:
				orientation = -1
				$Sprite2D.flip_h = true
				$TrapPlacementPosition.position.x = -abs($TrapPlacementPosition.position.x)
	else:
		if Input.is_action_just_pressed("move_left_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckLeft.play()
		if Input.is_action_just_pressed("move_right_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckRight.play()

	move_and_slide()

func dropped_in_jam():
	is_in_jam = true
	remaining_jam_uses = MAX_JAM_USES
	$SfxDropInJam.play()
	
func left_jam():
	is_in_jam = false
