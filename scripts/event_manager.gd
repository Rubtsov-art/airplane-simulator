extends Node

var game: Node
var extra_event := ""
var next_event := 20.0
var event_left := 0.0
var turbulence_phase := 0.0

func _ready():
    game = get_parent()

func _process(delta):
    if game == null or bool(game.get("game_over")): return
    if not bool(game.get("has_flown")): return
    if extra_event == "":
        next_event -= delta
        if next_event <= 0.0 and String(game.get("active_failure")) == "":
            start_event()
    else:
        event_left -= delta
        apply_event(delta)
        if event_left <= 0.0 and extra_event != "turbulence":
            game.call("fail_flight",failure_text())
            extra_event = ""

func start_event():
    next_event = randf_range(28.0,48.0)
    var choices := ["turbulence","icing","wiper_jam","gear_warning"]
    if not bool(game.get("raining")):
        choices.erase("wiper_jam")
    extra_event = choices.pick_random()
    match extra_event:
        "turbulence":
            event_left = 7.0
            game.call("show_hint","⚠ СИЛЬНАЯ БОЛТАНКА! Держи самолёт ровно. Пассажирам это не понравится.")
        "icing":
            event_left = 24.0
            game.call("show_hint","⚠ ОБЛЕДЕНЕНИЕ КРЫЛА! Найди синюю кнопку ICE в кабине.")
        "wiper_jam":
            event_left = 20.0
            game.set("wipers_on",false)
            game.call("show_hint","⚠ ДВОРНИКИ ЗАКЛИНИЛО! Нажми WIPER на панели для перезапуска.")
        "gear_warning":
            event_left = 25.0
            game.call("show_hint","⚠ ШАССИ НЕ ОТВЕЧАЕТ! Переключи GEAR на панели.")

func apply_event(delta):
    match extra_event:
        "turbulence":
            turbulence_phase += delta*12.0
            var p = game.get("plane")
            if p:
                p.rotation.z = sin(turbulence_phase)*0.045
            if event_left <= 0.0:
                if p: p.rotation.z = 0.0
                extra_event = ""
                game.call("show_hint","Болтанка закончилась. Можно снова делать вид, что всё было под контролем.")
        "icing":
            game.set("speed",max(0.0,float(game.get("speed"))-delta*1.5))
        "wiper_jam":
            game.set("wipers_on",false)

func cockpit_action(action: String):
    if extra_event == "icing" and action == "deice":
        resolve_event("Лёд сошёл с крыла.")
    elif extra_event == "wiper_jam" and action == "wiper_reset":
        resolve_event("Дворники снова работают.")
    elif extra_event == "gear_warning" and action == "gear":
        resolve_event("Шасси снова отвечает на команды.")

func resolve_event(message: String):
    extra_event = ""
    event_left = 0.0
    next_event = randf_range(30.0,50.0)
    game.call("show_hint",message)

func failure_text() -> String:
    match extra_event:
        "icing": return "самолёт слишком долго летел с обледенением!"
        "wiper_jam": return "в ливне так и не удалось восстановить дворники!"
        "gear_warning": return "неисправность шасси не была устранена!"
    return "аварийная ситуация вышла из-под контроля!"
