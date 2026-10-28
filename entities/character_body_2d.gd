extends CharacterBody2D

@export var speed: float = 240.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		get_tree().call_group("game_manager", "game_over")
