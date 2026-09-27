extends Node3D

var fuel := 35.0
var throttle := 0.0
var speed := 0.0
var altitude := 0.0
var engine_on := false
var wipers_on := false
var seated := true
var raining := false
var game_over := false
var refueling := false
var tutorial_step := 0
var bird_timer := 7.0

var plane: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var hint: Label
var dirt: ColorRect
var rain_overlay: ColorRect
var birds: Array[Node3D] = []

func _ready():
    build_world()
    build_plane()
    build_hud()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    show_hint("ОБУЧЕНИЕ: выйди из самолёта кнопкой ВСТАТЬ и заправь его.")

func box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color):
    var body = StaticBody3D.new()
    body.name = name
    body.position = pos
    parent.add_child(body)
    var mesh = MeshInstance3D.new()
    var shape_mesh = BoxMesh.new()
    shape_mesh.size = size
    mesh.mesh = shape_mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    var col = CollisionShape3D.new()
    var s = BoxShape3D.new()
    s.size = size
    col.shape = s
    body.add_child(col)
    return body

func build_world():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.38,0.68,0.9)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color.WHITE
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-25,0)
    sun.shadow_enabled = true
    add_child(sun)
    box(self,"Ground",Vector3(0,-1.1,0),Vector3(180,1,600),Color(0.18,0.42,0.16))
    box(self,"Runway",Vector3(0,-0.55,0),Vector3(36,0.1,500),Color(0.12,0.12,0.14))
    for z in range(-220,221,20):
        box(self,"Mark",Vector3(0,-0.47,z),Vector3(0.5,0.05,8),Color.WHITE)
    box(self,"FuelStation",Vector3(12,0,160),Vector3(4,4,4),Color(0.9,0.65,0.08))

func build_plane():
    plane = Node3D.new()
    plane.name = "TrainingPlane"
    plane.position = Vector3(0,1.2,170)
    add_child(plane)
    box(plane,"Floor",Vector3(0,0,0),Vector3(5,0.25,16),Color(0.18,0.2,0.23))
    box(plane,"LeftWall",Vector3(-2.5,1.5,1),Vector3(0.2,3,14),Color(0.72,0.75,0.78))
    box(plane,"RightWall",Vector3(2.5,1.5,1),Vector3(0.2,3,14),Color(0.72,0.75,0.78))
    box(plane,"Roof",Vector3(0,3,1),Vector3(5,0.2,14),Color(0.65,0.68,0.72))
    box(plane,"Dashboard",Vector3(0,1.05,-5.6),Vector3(4.8,1.6,0.8),Color(0.06,0.07,0.08))
    for z in [-1.0,1.0,3.0,5.0]:
        box(plane,"SeatL",Vector3(-1.3,0.65,z),Vector3(0.8,1.3,0.8),Color(0.16,0.22,0.32))
        box(plane,"SeatR",Vector3(1.3,0.65,z),Vector3(0.8,1.3,0.8),Color(0.16,0.22,0.32))
    player = CharacterBody3D.new()
    player.position = Vector3(0,1.15,-3.8)
    plane.add_child(player)
    camera = Camera3D.new()
    camera.position = Vector3(0,0.65,0)
    player.add_child(camera)

func build_hud():
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(20,18)
    hud.add_theme_font_size_override("font_size",21)
    layer.add_child(hud)
    hint = Label.new()
    hint.position = Vector2(170,625)
    hint.size = Vector2(940,70)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size",23)
    layer.add_child(hint)
    dirt = ColorRect.new()
    dirt.size = Vector2(1280,720)
    dirt.color = Color(0.32,0.22,0.08,0.03)
    dirt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(dirt)
    rain_overlay = ColorRect.new()
    rain_overlay.size = Vector2(1280,720)
    rain_overlay.color = Color(0.35,0.55,0.72,0)
    rain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(rain_overlay)
    add_touch_button(layer,"◀",Vector2(25,525),func(): steer(-1))
    add_touch_button(layer,"▶",Vector2(125,525),func(): steer(1))
    add_touch_button(layer,"ТЯГА +",Vector2(1030,470),func(): change_throttle(0.12))
    add_touch_button(layer,"ТЯГА -",Vector2(1030,535),func(): change_throttle(-0.12))
    add_touch_button(layer,"ДЕЙСТВИЕ",Vector2(520,540),func(): interact())
    add_touch_button(layer,"ВСТАТЬ",Vector2(700,540),func(): toggle_seat())
    add_touch_button(layer,"ДВОРНИКИ",Vector2(850,540),func(): toggle_wipers())

func add_touch_button(parent: Node, title: String, pos: Vector2, callback: Callable):
    var b = Button.new()
    b.text = title
    b.position = pos
    b.size = Vector2(150,55)
    b.add_theme_font_size_override("font_size",18)
    b.pressed.connect(callback)
    parent.add_child(b)

func _process(delta):
    if game_over: return
    if engine_on:
        fuel = max(0.0,fuel-delta*(0.02+throttle*0.05))
        if fuel <= 0:
            engine_on = false
            show_hint("Топливо закончилось! Попробуй посадить самолёт.")
    if refueling and not engine_on:
        fuel = min(100.0,fuel+delta*18.0)
        if fuel >= 100:
            refueling = false
            tutorial_step = max(tutorial_step,1)
            show_hint("Бак полный. Вернись в кабину, сядь и запусти двигатель.")
    if seated:
        speed = move_toward(speed,throttle*210.0 if engine_on else 0.0,delta*18.0)
        plane.translate(Vector3(0,0,-speed*delta*0.08))
        if speed > 90 and Input.is_action_pressed("pitch_up"):
            altitude += delta*35.0
        if speed > 90 and Input.is_action_pressed("pitch_down"):
            altitude = max(0.0,altitude-delta*35.0)
        plane.position.y = 1.2+altitude
    else:
        var v = Input.get_vector("move_left","move_right","move_forward","move_back")
        player.velocity = player.transform.basis*Vector3(v.x,0,v.y)*3.5
        player.move_and_slide()
    bird_timer -= delta
    if altitude > 3 and bird_timer <= 0:
        spawn_bird()
        bird_timer = randf_range(5.0,10.0)
    update_birds(delta)
    if altitude > 15 and not raining and randf() < delta*0.015:
        raining = true
        show_hint("Начался дождь! Включи дворники.")
    dirt.color.a = min(0.38,dirt.color.a+delta*(0.004 if raining else 0.001))
    rain_overlay.color.a = 0.12 if raining else 0.0
    if wipers_on:
        dirt.color.a = max(0.0,dirt.color.a-delta*0.28)
    hud.text = "ТОПЛИВО %d%%   ТЯГА %d%%   СКОРОСТЬ %d   ВЫСОТА %d м\n%s | ДВОРНИКИ %s | %s" % [fuel,throttle*100,speed,altitude,"ДВИГАТЕЛЬ ВКЛ" if engine_on else "ДВИГАТЕЛЬ ВЫКЛ","ВКЛ" if wipers_on else "ВЫКЛ","В КРЕСЛЕ" if seated else "ХОЖУ"]
    if Input.is_action_just_pressed("interact"): interact()

func spawn_bird():
    var bird = Node3D.new()
    bird.position = plane.position+Vector3(randf_range(-18,18),randf_range(-4,7),-65)
    add_child(bird)
    box(bird,"BirdBody",Vector3.ZERO,Vector3(0.7,0.35,0.9),Color(0.16,0.12,0.08))
    box(bird,"WingL",Vector3(-0.7,0,0),Vector3(1.2,0.08,0.4),Color(0.22,0.18,0.13))
    box(bird,"WingR",Vector3(0.7,0,0),Vector3(1.2,0.08,0.4),Color(0.22,0.18,0.13))
    birds.append(bird)

func update_birds(delta):
    for bird in birds.duplicate():
        bird.position.z += delta*22.0
        if bird.position.distance_to(plane.position) < 3.3:
            fail_flight("Ты столкнулся с птицей!")
            return
        if bird.position.z > plane.position.z+30:
            birds.erase(bird)
            bird.queue_free()

func fail_flight(reason: String):
    game_over = true
    throttle = 0
    hint.text = "РЕЙС ПРОВАЛЕН — "+reason+"  Перезапусти игру."

func interact():
    if not seated:
        var world_pos = player.global_position
        if world_pos.distance_to(Vector3(12,0,160)) < 9:
            refueling = true
            show_hint("Шланг подключён. Идёт заправка...")
            return
    if seated and not engine_on and fuel > 0:
        engine_on = true
        show_hint("Двигатель запущен. Увеличивай тягу и выруливай на полосу.")
    else:
        toggle_wipers()

func toggle_seat():
    seated = not seated
    if seated:
        player.position = Vector3(0,1.15,-3.8)
        show_hint("Ты снова за штурвалом.")
    else:
        show_hint("Ты встал. WASD — ходить. Можно выйти через открытую заднюю часть.")

func toggle_wipers():
    wipers_on = not wipers_on

func change_throttle(amount: float):
    if seated:
        throttle = clamp(throttle+amount,0.0,1.0)

func steer(direction: float):
    if seated:
        plane.rotation.y += direction*0.035

func show_hint(text: String):
    hint.text = text

func _input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x*0.002)
        camera.rotation.x = clamp(camera.rotation.x-event.relative.y*0.002,-1.2,1.2)
    if event is InputEventKey and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
