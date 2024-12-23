class_name Ball extends CharacterBody2D

const SPEED = 350.0 #450.0

@export var animation_player: AnimationPlayer
@export var hit_particles_scene: PackedScene

@onready var powerup_slow_active = false
@onready var current_direction: Vector2 = Vector2.ZERO

signal on_screen_exited(ball: Ball)


func _ready() -> void:
	add_to_group("Ball")


func start_moving(direction: Vector2) -> void:
	current_direction = direction.normalized()
	velocity = current_direction * SPEED


func _physics_process(delta: float) -> void:
	# Remove collision with paddle when below a certain height
	if position.y >= 520:
		set_collision_mask_value(2, false)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var collision_body := collision.get_collider()
		if collision_body.has_method("on_collision"):
			collision_body.on_collision()

		if collision.get_collider() is Paddle:
			var paddle = collision.get_collider() as Paddle
			paddle.on_ball_hit(self, collision)
		else:
			var bounce_velocity: Vector2 = velocity.bounce(collision.get_normal())
			current_direction = bounce_velocity.normalized()

			if collision_body.name == "DefaultLevel":
				AudioManager.play("res://assets/audio/sfx/ball_hit_wall.wav")

			# Making sure the ball horizontal movement is never within a 7 degree angle
			# Otherwise it may get stuck going only horizontal
			var angle := rad_to_deg(collision.get_normal().angle_to(bounce_velocity))
			if angle > -7 and angle < 7 and collision.get_normal() != Vector2.DOWN:
				var offset_angle: float
				if angle > 0:
					offset_angle = rad_to_deg(current_direction.angle()) + 10
				else:
					offset_angle = rad_to_deg(current_direction.angle()) - 10
				current_direction = Vector2.from_angle(deg_to_rad(offset_angle))

			velocity = current_direction * bounce_velocity.length()
			var camera := get_tree().get_first_node_in_group("Camera") as Camera
			camera.shake(Vector2(2, 2))

		animation_player.play("hit")
		var hit_particles := hit_particles_scene.instantiate() as GPUParticles2D
		add_child(hit_particles)
		hit_particles.global_position = collision.get_position()
		hit_particles.global_rotation = collision.get_normal().angle()
		hit_particles.emitting = true
		_move_ball(delta)


func _move_ball(delta: float) -> void:
	if powerup_slow_active:
		velocity *= randf_range(1.01, 1.05)
	if velocity != Vector2.ZERO:
		move_and_collide(velocity * delta)


func stop_moving() -> void:
	velocity = Vector2.ZERO
	current_direction = Vector2.ZERO


func normal_speed() -> void:
	velocity = current_direction * SPEED
	powerup_slow_active = false


func slow_speed() -> void:
	velocity /= 2
	powerup_slow_active = true


func _on_screen_exited() -> void:
	on_screen_exited.emit(self)


func disable_collision(disable: bool = true) -> void:
	$CollisionShape2D.disabled = disable
