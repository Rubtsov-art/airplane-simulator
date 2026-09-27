extends CanvasLayer

var game: Node
var overlay: ColorRect
var money_label: Label
var plane_label: Label
var airport_label: Label
var status_label: Label
var money := 0
var selected_plane := 0
var selected_airport := 0
var rewarded := false
var flight_started := false

var planes := [
    {"name":"Swift 100","price":0},
    {"name":"Comet 220","price":500},
    {"name":"Atlas 400","price":1500}
]
var airports := [
    {"name":"Greenfield","price":0},
    {"name":"Coastline","price":700},
    {"name":"Snowpeak","price":1800}
]
var unlocked_planes := [0]
var unlocked_airports := [0]

func _ready():
    game = get_parent()
    layer = 20
    load_save()
    build_menu()
    update_menu()

func make_label(parent: Control, text_value: String, pos: Vector2, size: Vector2, font := 28) -> Label:
    var l := Label.new()
    l.text = text_value
    l.position = pos
    l.size = size
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size",font)
    parent.add_child(l)
    return l

func make_button(parent: Control, text_value: String, pos: Vector2, size: Vector2, cb: Callable) -> Button:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size",22)
    b.pressed.connect(cb)
    parent.add_child(b)
    return b

func build_menu():
    overlay = ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.025,0.045,0.075,0.94)
    add_child(overlay)
    make_label(overlay,"AIRPLANE SIMULATOR",Vector2(300,75),Vector2(680,80),46)
    money_label = make_label(overlay,"",Vector2(420,155),Vector2(440,55),28)
    plane_label = make_label(overlay,"",Vector2(390,240),Vector2(500,50),25)
    airport_label = make_label(overlay,"",Vector2(390,330),Vector2(500,50),25)
    make_button(overlay,"САМОЛЁТ ▶",Vector2(475,290),Vector2(330,48),cycle_plane)
    make_button(overlay,"АЭРОПОРТ ▶",Vector2(475,380),Vector2(330,48),cycle_airport)
    make_button(overlay,"✈ НАЧАТЬ РЕЙС",Vector2(440,475),Vector2(400,70),start_flight)
    status_label = make_label(overlay,"",Vector2(250,565),Vector2(780,55),20)
    make_label(overlay,"Успешный рейс: +250 монет",Vector2(390,625),Vector2(500,35),17)

func update_menu():
    money_label.text = "МОНЕТЫ: %d" % money
    var p = planes[selected_plane]
    var a = airports[selected_airport]
    plane_label.text = "САМОЛЁТ: %s%s" % [p.name,"" if selected_plane in unlocked_planes else "  🔒 %d" % p.price]
    airport_label.text = "АЭРОПОРТ: %s%s" % [a.name,"" if selected_airport in unlocked_airports else "  🔒 %d" % a.price]

func cycle_plane():
    var next := (selected_plane+1)%planes.size()
    if next in unlocked_planes:
        selected_plane = next
        status_label.text = "Выбран %s" % planes[next].name
    elif money >= int(planes[next].price):
        money -= int(planes[next].price)
        unlocked_planes.append(next)
        selected_plane = next
        status_label.text = "Открыт новый самолёт!"
        save_game()
    else:
        selected_plane = next
        status_label.text = "Нужно ещё %d монет." % (int(planes[next].price)-money)
    update_menu()

func cycle_airport():
    var next := (selected_airport+1)%airports.size()
    if next in unlocked_airports:
        selected_airport = next
        status_label.text = "Выбран аэропорт %s" % airports[next].name
    elif money >= int(airports[next].price):
        money -= int(airports[next].price)
        unlocked_airports.append(next)
        selected_airport = next
        status_label.text = "Открыт новый аэропорт!"
        save_game()
    else:
        selected_airport = next
        status_label.text = "Нужно ещё %d монет." % (int(airports[next].price)-money)
    update_menu()

func start_flight():
    if not selected_plane in unlocked_planes:
        status_label.text = "Сначала открой этот самолёт."
        return
    if not selected_airport in unlocked_airports:
        status_label.text = "Сначала открой этот аэропорт."
        return
    overlay.visible = false
    flight_started = true
    apply_selection()
    game.call("show_hint","Рейс начался. Сначала заправь самолёт и подготовься к взлёту.")

func apply_selection():
    var p = game.get("plane")
    if p:
        match selected_plane:
            0: p.scale = Vector3(0.92,0.92,0.92)
            1: p.scale = Vector3(1.0,1.0,1.0)
            2: p.scale = Vector3(1.08,1.04,1.16)
    var envs = game.find_children("*","WorldEnvironment",true,false)
    if not envs.is_empty() and envs[0].environment:
        match selected_airport:
            0: envs[0].environment.background_color = Color(0.38,0.68,0.9)
            1: envs[0].environment.background_color = Color(0.28,0.62,0.82)
            2: envs[0].environment.background_color = Color(0.68,0.78,0.86)

func _process(_delta):
    if not flight_started or rewarded or game == null: return
    var h = game.get("hint")
    if h and String(h.text).begins_with("РЕЙС ВЫПОЛНЕН"):
        rewarded = true
        money += 250
        save_game()
        status_label.text = "Рейс выполнен! +250 монет. Перезапусти сцену для следующего рейса."
        update_menu()
        overlay.visible = true

func save_game():
    var cfg := ConfigFile.new()
    cfg.set_value("progress","money",money)
    cfg.set_value("progress","planes",unlocked_planes)
    cfg.set_value("progress","airports",unlocked_airports)
    cfg.set_value("progress","selected_plane",selected_plane)
    cfg.set_value("progress","selected_airport",selected_airport)
    cfg.save("user://progress.cfg")

func load_save():
    var cfg := ConfigFile.new()
    if cfg.load("user://progress.cfg") != OK: return
    money = int(cfg.get_value("progress","money",0))
    unlocked_planes = Array(cfg.get_value("progress","planes",[0]))
    unlocked_airports = Array(cfg.get_value("progress","airports",[0]))
    selected_plane = int(cfg.get_value("progress","selected_plane",0))
    selected_airport = int(cfg.get_value("progress","selected_airport",0))
