extends Node

var players := {}
var paths := {
    "engine": "res://audio/engine_loop.ogg",
    "music": "res://audio/flight_music.ogg",
    "rain": "res://audio/rain_loop.ogg",
    "wipers": "res://audio/wipers_loop.ogg",
    "alarm": "res://audio/alarm_loop.ogg",
    "click": "res://audio/button_click.ogg",
    "fuel": "res://audio/refuel_loop.ogg",
    "success": "res://audio/landing_success.ogg",
    "fail": "res://audio/flight_fail.ogg"
}

func _ready():
    for key in paths:
        var p = AudioStreamPlayer.new()
        p.name = key
        add_child(p)
        players[key] = p
        if ResourceLoader.exists(paths[key]):
            p.stream = load(paths[key])
    play_loop("music",-22.0)

func play_loop(name: String, volume_db := -10.0):
    var p: AudioStreamPlayer = players.get(name)
    if p and p.stream and not p.playing:
        p.volume_db = volume_db
        p.play()

func stop(name: String):
    var p: AudioStreamPlayer = players.get(name)
    if p and p.playing: p.stop()

func one_shot(name: String, volume_db := 0.0):
    var p: AudioStreamPlayer = players.get(name)
    if p and p.stream:
        p.volume_db = volume_db
        p.play()

func update_engine(on: bool, throttle: float):
    var p: AudioStreamPlayer = players.get("engine")
    if not p or not p.stream: return
    if on:
        if not p.playing: p.play()
        p.pitch_scale = 0.72 + throttle*0.72
        p.volume_db = -13.0 + throttle*8.0
    else:
        p.stop()

func update_ambience(raining: bool, wipers: bool, alarm: bool, refueling: bool):
    if raining: play_loop("rain",-13.0)
    else: stop("rain")
    if wipers: play_loop("wipers",-10.0)
    else: stop("wipers")
    if alarm: play_loop("alarm",-5.0)
    else: stop("alarm")
    if refueling: play_loop("fuel",-9.0)
    else: stop("fuel")
