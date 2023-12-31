extends CharacterBody2D

@export var player_id : int = 0
@export var trap_scene : PackedScene
@export var projectile_scene : PackedScene
@export var player_colors : PackedColorArray

const SPEED = 400.0
const JUMP_VELOCITY = -460.0
const MAX_JAM_USES = 5

var stuck_counter = 0
var sticky_trap
var orientation = 1 # 1 => looking right; -1 => looking left;
var is_in_air = false
var is_in_jam = true
var is_aiming = false
var is_stunned = false
var remaining_jam_uses = MAX_JAM_USES
var filled_jam_position
var empty_jam_position

const PROJECTILE_SPEED = 600.0
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
	$ShakeIndicator.visible = true
	if not is_stuck():
		$SfxStuck.play()
		sticky_trap = trap
		velocity.x = 0

func is_stuck():
	return is_instance_valid(sticky_trap) and sticky_trap.is_sticky()

func _ready():
	# set player jam color
	var color = player_colors[player_id]
	$ClipArea/JamSprite.modulate = color
	$ShakeIndicator.modulate = color
	$AimArrow.modulate = color
	filled_jam_position = $ClipArea/JamSprite.position
	empty_jam_position = $ClipArea/BottomOfJar.position

func can_place_trap():
	return is_on_floor() \
		and not is_in_jam \
		and remaining_jam_uses > 0

func use_jam_charge():
	remaining_jam_uses -= 1
	update_jam_level()
	
func update_jam_level():
	var next_position = lerp(empty_jam_position, filled_jam_position, remaining_jam_uses / float(MAX_JAM_USES))
	$ClipArea/JamSprite.position = (next_position)

func place_trap():
	# try to place trap
	var original_placement_position = $TrapPlacementPosition.position
	var timeout = 40
	# find closest point where ground is detected at both ends of the placed trap
	while(timeout > 0 and not ($TrapPlacementPosition/TrapPlacementRaycastLeft.is_colliding() \
	and $TrapPlacementPosition/TrapPlacementRaycastRight.is_colliding())):
		$TrapPlacementPosition.position.x -= sign(original_placement_position.x)
		$TrapPlacementPosition/TrapPlacementRaycastLeft.force_update_transform()
		$TrapPlacementPosition/TrapPlacementRaycastLeft.force_raycast_update()
		$TrapPlacementPosition/TrapPlacementRaycastRight.force_update_transform()
		$TrapPlacementPosition/TrapPlacementRaycastRight.force_raycast_update()
		timeout -= 1
	$TrapPlacementPosition/OtherTrapCheckRaycastLeft.force_update_transform()
	$TrapPlacementPosition/OtherTrapCheckRaycastLeft.force_raycast_update()
	$TrapPlacementPosition/OtherTrapCheckRaycastLeft.collide_with_areas = true
	$TrapPlacementPosition/OtherTrapCheckRaycastRight.force_update_transform()
	$TrapPlacementPosition/OtherTrapCheckRaycastRight.force_raycast_update()
	$TrapPlacementPosition/OtherTrapCheckRaycastRight.collide_with_areas = true
	var has_other_traps = $TrapPlacementPosition/OtherTrapCheckRaycastLeft.is_colliding() \
		or $TrapPlacementPosition/OtherTrapCheckRaycastRight.is_colliding()
	# only if actual free area was found$TrapPlacementPosition
	if timeout > 0 and not has_other_traps:
		var trap = trap_scene.instantiate()
		trap.belongs_to = self.player_id
		trap.color = player_colors[player_id]
		trap.position = self.position + $TrapPlacementPosition.position
		get_tree().current_scene.add_child(trap)
		use_jam_charge()
		$SfxPlaceTrap.play()
		
	$TrapPlacementPosition.position = original_placement_position

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		var downward_gravity_factor = 1.0 if velocity.y < 0.0 else DOWNWARD_GRAVITY_GRAVITY
		velocity.y += gravity * downward_gravity_factor * delta
		is_in_air = true
	else:
		if is_in_air and not is_in_jam:
			# only once on land
			$SfxLand.play()
		is_in_air = false
		
	# fast exit if stunned
	if is_stunned:
		move_and_slide()
		return
	
	var aim_direction = Input.get_vector(
		"aim_left_%s" % player_id, 
		"aim_right_%s" % player_id, 
		"aim_up_%s" % player_id, 
		"aim_down_%s" % player_id
	)
	var aim_is_neutral = aim_direction.length_squared() < 0.01
	
	if Input.is_action_just_pressed("attack_%s" % player_id):
		is_aiming = true
	
	if Input.is_action_just_released("attack_%s" % player_id):
		is_aiming = false

		if aim_is_neutral:
			if can_place_trap():
				place_trap()
		else:
			if remaining_jam_uses > 0:
				shoot_projectile(aim_direction)
	if is_aiming and not aim_is_neutral and remaining_jam_uses > 0:
		$AimArrow.visible = true
		$AimArrow.look_at($AimArrow.global_position + aim_direction)
	else:
		$AimArrow.visible = false

	if not is_stuck():
		$ShakeIndicator.visible = false
		# Handle Jump
		if Input.is_action_just_pressed("jump_%s" % player_id) and is_on_floor() and not is_aiming:
			velocity.y = jump_velocity
			$SfxJump.play()

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("move_left_%s" % player_id, "move_right_%s" % player_id) \
			if not is_aiming else 0.0
		# Might be nice to interpolate between ground speed and air speed
		# However we must be careful to avoid "ice" physics doing that 
		var speed = GROUND_SPEED if is_on_floor() else AIR_SPEED
		if direction:
			$JarSprite.play("walk")
			velocity.x = direction * speed
		else:
			$JarSprite.play("idle")
			velocity.x = move_toward(velocity.x, 0, speed)
		
		# set orientation
		if abs(velocity.x) > 0.01:
			if velocity.x > 0:
				orientation = 1
				$JarSprite.flip_h = true
				$TrapPlacementPosition.position.x = abs($TrapPlacementPosition.position.x)
			else:
				orientation = -1
				$JarSprite.flip_h = false
				$TrapPlacementPosition.position.x = -abs($TrapPlacementPosition.position.x)
	else:
		if Input.is_action_just_pressed("move_left_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckLeft.play()
		if Input.is_action_just_pressed("move_right_%s" % player_id):
			sticky_trap.reduce_stickyness()
			$SfxFootStuckRight.play()

	if is_aiming:
		$JarSprite.play("shot_aim")

	move_and_slide()

func dropped_in_jam():
	is_in_jam = true
	remaining_jam_uses = MAX_JAM_USES
	$ClipArea/JamSprite.position = filled_jam_position
	
	$SfxDropInJam.play()
	
func left_jam():
	is_in_jam = false
	
func shoot_projectile(direction: Vector2):
	var projectile = projectile_scene.instantiate()
	projectile.position = $AimArrow/AimArrowSprite.global_position
	projectile.rotation = $AimArrow/AimArrowSprite.global_rotation
	projectile.linear_velocity = direction.normalized() * PROJECTILE_SPEED
	projectile.push_velocity = projectile.linear_velocity / 4.0
	projectile.modulate = player_colors[player_id]
	use_jam_charge()
	$SfxShoot.play()
	get_tree().current_scene.add_child(projectile)

func stun():
	$SfxStun.play()
	is_stunned = true
	$StunTimer.start()


func _on_stun_timer_timeout():
	is_stunned = false
