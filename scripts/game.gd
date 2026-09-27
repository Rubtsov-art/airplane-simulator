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
var fuel_hose: MeshInstance3D
var has_flown := false
var landing_target_z := -170.0
var failure_timer := 16.0
var active_failure := ""
var failure_time_left := 0.0
var held_item := ""
var extinguisher_pos := Vector3(-1.9,0.8,5.7)
var tools_pos := Vector3(1.9,0.8,5.7)
var repair_panel_pos := Vector3(2.25,1.3,2.8)
var fire_panel_pos := Vector3(-2.25,1.3,2.8)

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
    # Exterior silhouette: nose, wings, tail, engines and landing gear.
    box(plane,"Nose",Vector3(0,0.7,-8.0),Vector3(4.0,2.0,4.0),Color(0.92,0.94,0.96))
    box(plane,"LeftWing",Vector3(-6.5,0.15,0.8),Vector3(8.0,0.25,3.0),Color(0.88,0.9,0.93))
    box(plane,"RightWing",Vector3(6.5,0.15,0.8),Vector3(8.0,0.25,3.0),Color(0.88,0.9,0.93))
    box(plane,"Tail",Vector3(0,2.5,8.0),Vector3(0.35,4.5,3.0),Color(0.85,0.1,0.12))
    box(plane,"EngineL",Vector3(-5.2,-0.45,0.0),Vector3(2.0,1.7,3.2),Color(0.25,0.28,0.32))
    box(plane,"EngineR",Vector3(5.2,-0.45,0.0),Vector3(2.0,1.7,3.2),Color(0.25,0.28,0.32))
    box(plane,"GearL",Vector3(-2.0,-1.0,2.0),Vector3(0.45,1.8,0.45),Color(0.05,0.05,0.05))
    box(plane,"GearR",Vector3(2.0,-1.0,2.0),Vector3(0.45,1.8,0.45),Color(0.05,0.05,0.05))
    box(plane,"NoseGear",Vector3(0,-1.0,-5.0),Vector3(0.4,1.7,0.4),Color(0.05,0.05,0.05))
    box(plane,"EquipmentCabinet",Vector3(0,1.1,6.5),Vector3(4.4,2.1,0.55),Color(0.48,0.5,0.52))
    box(plane,"Extinguisher",extinguisher_pos,Vector3(0.45,1.2,0.45),Color(0.85,0.06,0.04))
    box(plane,"Toolbox",tools_pos,Vector3(0.9,0.45,0.55),Color(0.08,0.16,0.7))
    box(plane,"ElectricalPanel",repair_panel_pos,Vector3(0.25,1.2,1.2),Color(0.12,0.12,0.14))
    box(plane,"FireAccess",fire_panel_pos,Vector3(0.25,1.2,1.2),Color(0.45,0.08,0.04))
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
            if fuel_hose: fuel_hose.visible = false
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
        if altitude > 8: has_flown = true
        check_landing()
    else:
        var v = Input.get_vector("move_left","move_right","move_forward","move_back")
        player.velocity = player.transform.basis*Vector3(v.x,0,v.y)*3.5
        player.move_and_slide()
    if has_flown and active_failure == "":
        failure_timer -= delta
        if failure_timer <= 0:
            start_random_failure()
    if active_failure != "":
        failure_time_left -= delta
        if active_failure == "engine_fire":
            speed = max(0.0,speed-delta*3.0)
        elif active_failure == "electrical":
            wipers_on = false
        if failure_time_left <= 0:
            fail_flight("поломка не была устранена вовремя!")
            return
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
    var problem = "НОРМА" if active_failure == "" else "АВАРИЯ: "+active_failure
    var item = "ничего" if held_item == "" else held_item
    hud.text = "ТОПЛИВО %d%%   ТЯГА %d%%   СКОРОСТЬ %d   ВЫСОТА %d м\n%s | ДВОРНИКИ %s | %s" % [fuel,throttle*100,speed,altitude,"ДВИГАТЕЛЬ ВКЛ" if engine_on else "ДВИГАТЕЛЬ ВЫКЛ","ВКЛ" if wipers_on else "ВЫКЛ","В КРЕСЛЕ" if seated else "ХОЖУ"] + "\nСИСТЕМА: "+problem+" | В РУКАХ: "+item
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
            show_fuel_hose()
            show_hint("Шланг подключён к самолёту. Идёт заправка...")
            return
        var local_pos = player.position
        if local_pos.distance_to(extinguisher_pos) < 2.0:
            held_item = "огнетушитель"
            show_hint("Ты взял огнетушитель.")
            return
        if local_pos.distance_to(tools_pos) < 2.0:
            held_item = "инструменты"
            show_hint("Ты взял набор инструментов.")
            return
        if active_failure == "engine_fire" and local_pos.distance_to(fire_panel_pos) < 2.0:
            if held_item == "огнетушитель":
                fix_failure("Пожар потушен! Возвращайся к управлению.")
            else:
                show_hint("Здесь пожар! Нужен огнетушитель из заднего шкафчика.")
            return
        if active_failure == "electrical" and local_pos.distance_to(repair_panel_pos) < 2.0:
            if held_item == "инструменты":
                fix_failure("Электрика починена. Системы снова работают.")
            else:
                show_hint("Панель сломана. Нужны инструменты из заднего шкафчика.")
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


func show_fuel_hose():
    if fuel_hose == null:
        fuel_hose = MeshInstance3D.new()
        var cyl = CylinderMesh.new()
        cyl.top_radius = 0.09
        cyl.bottom_radius = 0.09
        cyl.height = 10.0
        fuel_hose.mesh = cyl
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.08,0.08,0.08)
        fuel_hose.material_override = mat
        add_child(fuel_hose)
    var start = Vector3(12,1.0,160)
    var finish = plane.global_position + Vector3(2.7,0.0,2.0)
    var mid = (start+finish)*0.5
    fuel_hose.global_position = mid
    fuel_hose.scale.y = start.distance_to(finish)/10.0
    fuel_hose.look_at(finish,Vector3.UP)
    fuel_hose.rotate_object_local(Vector3.RIGHT,PI/2.0)
    fuel_hose.visible = true

func check_landing():
    if not has_flown or game_over: return
    # Landing zone is the far half of the same runway.
    if altitude <= 0.5 and plane.position.z < landing_target_z:
        if speed <= 115.0:
            game_over = true
            throttle = 0.0
            engine_on = false
            hint.text = "РЕЙС ВЫПОЛНЕН! Отличная посадка ✈"
        elif speed > 155.0:
            fail_flight("слишком высокая скорость при посадке!")


func start_random_failure():
    failure_timer = randf_range(22.0,38.0)
    failure_time_left = 24.0
    if randf() < 0.5:
        active_failure = "engine_fire"
        show_hint("⚠ ПОЖАР! Встань, возьми огнетушитель в заднем шкафчике и подойди к красной панели.")
    else:
        active_failure = "electrical"
        show_hint("⚠ СБОЙ ЭЛЕКТРИКИ! Возьми инструменты и почини правую панель.")

func fix_failure(message: String):
    active_failure = ""
    failure_time_left = 0.0
    held_item = ""
    failure_timer = randf_range(25.0,45.0)
    show_hint(message)
