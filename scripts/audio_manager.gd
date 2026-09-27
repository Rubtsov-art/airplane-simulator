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
    "fail": "res://audio/flight_fail.ogg",
    "door": "res://audio/door.ogg",
    "step": "res://audio/step.ogg"
}

func _ready():
    for key in paths:
        var p := AudioStreamPlayer.new()
        p.name = key
        add_child(p)
        players[key] = p
        if ResourceLoader.exists(paths[key]):
            p.stream = load(paths[key])
        else:
            p.stream = make_procedural_sound(key)
    play_loop("music",-25.0)

func make_procedural_sound(kind: String) -> AudioStreamWAV:
    var sample_rate := 8000
    var duration := 1.0
    var looped := kind in ["engine","music","rain","wipers","alarm","fuel"]
    match kind:
        "music": duration = 4.0
        "rain","wipers","alarm","fuel": duration = 2.0
        "click": duration = 0.12
        "success": duration = 1.2
        "fail": duration = 0.9
        "door": duration = 0.35
        "step": duration = 0.18
    var count := int(sample_rate*duration)
    var bytes := PackedByteArray()
    bytes.resize(count*2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 92831 + kind.hash()
    var smooth_noise := 0.0
    for i in range(count):
        var t := float(i)/sample_rate
        var x := 0.0
        match kind:
            "engine":
                x = 0.26*sin(TAU*62.0*t)+0.13*sin(TAU*124.0*t)+0.05*sin(TAU*248.0*t)+rng.randf_range(-0.025,0.025)
            "music":
                var beat := int(t)%4
                var roots := [130.81,98.0,110.0,87.31]
                var root: float = roots[beat]
                x = 0.055*(sin(TAU*root*t)+sin(TAU*root*1.25*t)+sin(TAU*root*1.5*t))
            "rain":
                smooth_noise = smooth_noise*0.82+rng.randf_range(-1.0,1.0)*0.18
                x = smooth_noise*0.22
            "wipers":
                var phase := fmod(t,1.0)
                var sweep := exp(-pow((phase-0.24)/0.075,2.0))+exp(-pow((phase-0.72)/0.075,2.0))
                x = sweep*rng.randf_range(-0.28,0.28)
            "alarm":
                var gate := 1.0 if fmod(t,0.5)<0.22 else 0.0
                var freq := 880.0 if int(t*2.0)%2==0 else 660.0
                x = 0.25*gate*sin(TAU*freq*t)
            "click":
                x = rng.randf_range(-0.55,0.55)*exp(-t*38.0)
            "fuel":
                x = 0.10*sin(TAU*95.0*t)+rng.randf_range(-0.04,0.04)
            "success":
                var notes := [523.25,659.25,783.99]
                var part := min(2,int(t/0.4))
                x = 0.28*sin(TAU*float(notes[part])*t)*fade_edges(t,duration)
            "fail":
                var freq := lerp(330.0,130.0,t/duration)
                x = 0.30*sin(TAU*freq*t)*fade_edges(t,duration)
            "door":
                x = 0.18*sin(TAU*(115.0-80.0*t)*t)+rng.randf_range(-0.08,0.08)*fade_edges(t,duration)
            "step":
                x = rng.randf_range(-0.32,0.32)*exp(-t*22.0)+0.12*sin(TAU*70.0*t)*exp(-t*15.0)
        var value := int(clamp(x,-1.0,1.0)*32767.0)
        bytes.encode_s16(i*2,value)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = sample_rate
    wav.stereo = false
    wav.data = bytes
    if looped:
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
        wav.loop_begin = 0
        wav.loop_end = count
    return wav

func fade_edges(t: float, duration: float) -> float:
    return clamp(min(t/0.04,(duration-t)/0.08),0.0,1.0)

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
        p.pitch_scale = randf_range(0.94,1.06) if name in ["click","step"] else 1.0
        p.play()

func update_engine(on: bool, throttle: float):
    var p: AudioStreamPlayer = players.get("engine")
    if not p or not p.stream: return
    if on:
        if not p.playing: p.play()
        p.pitch_scale = 0.72+throttle*0.72
        p.volume_db = -13.0+throttle*8.0
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
