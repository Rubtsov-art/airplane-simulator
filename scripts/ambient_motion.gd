extends Node

var game: Node
var time := 0.0
var step_timer := 0.0

func _ready():
    game = get_parent()

func _process(delta):
    if game == null: return
    time += delta
    animate_passengers()
    update_steps(delta)

func animate_passengers():
    for passenger in get_tree().get_nodes_in_group("passenger"):
        if not is_instance_valid(passenger): continue
        var worried := bool(passenger.get_meta("worried",false))
        if worried:
            passenger.rotation.y = sin(time*9.0)*0.08
            passenger.position.y = 0.85+abs(sin(time*7.0))*0.025
        else:
            passenger.rotation.y = sin(time*0.8+float(passenger.get_instance_id()%7))*0.012
            passenger.position.y = 0.85+sin(time*1.1+float(passenger.get_instance_id()%11))*0.008

func update_steps(delta):
    if bool(game.get("seated")):
        step_timer = 0.0
        return
    var p = game.get("player")
    if p == null: return
    if p.velocity.length() > 0.25:
        step_timer -= delta
        if step_timer <= 0.0:
            step_timer = 0.42
            var audio = game.get("audio_manager")
            if audio and audio.has_method("one_shot"):
                audio.call("one_shot","step",-9.0)
    else:
        step_timer = 0.0
