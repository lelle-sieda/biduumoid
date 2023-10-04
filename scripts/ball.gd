extends CharacterBody2D
class_name Ball

const __SPEED = 350.0

signal on_screen_exited(ball: Ball)

func _ready() -> void:
	add_to_group("Ball")


func start_moving(direction: Vector2) -> void:
	velocity = direction * __SPEED

	# Enable collision after some time (otherwise it will collide with paddle on start)
	if $CollisionShape2D.disabled:
		await get_tree().create_timer(0.05).timeout
		disable_collision(false)


func _physics_process(delta: float) -> void:
	if position.y >= 520:
		set_collision_mask_value(2, false)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var collision_body = collision.get_collider()
		if collision_body.has_method("on_collision"):
			collision_body.on_collision()

		if collision.get_collider() is Paddle:
			var paddle = collision.get_collider() as Paddle
			var paddle_pos: Vector2 = collision.get_position() - paddle.global_position
			paddle_pos.x /= (paddle.size / 2)
			paddle_pos.normalized()

			# If we hit the middle part of the paddle it reflects normally
			var degrees: float = clampf(paddle_pos.x * 75, -75, 75)
			if paddle_pos.x > -0.2 and paddle_pos.x < 0 and velocity.normalized().x > 0:
				degrees = absf(degrees)
			elif paddle_pos.x >= 0 and paddle_pos.x < 0.2 and velocity.normalized().x < 0:
				degrees *= -1

			# On the edge of the paddle it will go at a sharper angle
			var reflect_vector: Vector2 = Vector2.UP.rotated(deg_to_rad(degrees))
			velocity = reflect_vector * __SPEED
			move_and_collide(reflect_vector * delta)
			return

		var reflect = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal())
		move_and_collide(reflect * delta)


func _on_screen_exited() -> void:
	on_screen_exited.emit(self)


func disable_collision(disable: bool = true) -> void:
	$CollisionShape2D.set_deferred("disabled", disable)
