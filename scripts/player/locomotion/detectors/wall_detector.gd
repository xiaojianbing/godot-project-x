class_name WallDetector
extends RefCounted


func is_on_wall(actor: CharacterBody2D) -> bool:
	return actor != null and actor.is_on_wall_only()


func is_wall_sliding(actor: CharacterBody2D) -> bool:
	return is_on_wall(actor) and not actor.is_on_floor() and actor.velocity.y > 0.0


func can_wall_jump(actor: CharacterBody2D) -> bool:
	return is_on_wall(actor) and not actor.is_on_floor()


func get_wall_normal(actor: CharacterBody2D) -> Vector2:
	if actor == null:
		return Vector2.ZERO
	return actor.get_wall_normal()
