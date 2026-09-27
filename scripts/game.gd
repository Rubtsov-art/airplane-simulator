extends Node3D

var fuel := 100.0
var throttle := 0.0
var speed := 0.0
var altitude := 0.0
var engine_on := false
var wipers_on := false
var seated := true
var tutorial_step := 0

var plane: Node3D
var camera: Camera3D
var player: CharacterBody3D
var hud: Label
var hint: Label
var windshield_dirt: ColorRect

func _ready():
    build_world()
    build_plane()
    build_hud()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    show_tutorial("Добро пожаловать! Нажми E, чтобы запустить двигатель.")

func make_box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color):
    var body = StaticBody3D.new()
    body.name = name
    body.position = pos
    parent.add_child(body)
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    var shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = size
    shape.shape = box_shape
    body.add_child(shape)
    return body

func build_world():
    var env = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.38, 0.68, 0.9)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color.WHITE
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.shadow_enabled = true
    add_child(sun)
    make_box(self, "Runway", Vector3(0,-1,0), Vector3(36,1,500), Color(0.12,0.12,0.14))
    for z in range(-220,221,20):
        make_box(self, "Mark", Vector3(0,-0.47,z), Vector3(0.5,0.05,8), Color.WHITE)

func build_plane():
    plane = Node3D.new()
    plane.name = "TrainingPlane"
    plane.position = Vector3(0,1.2,170)
    add_child(plane)
    make_box(plane,"Floor",Vector3(0,0,0),Vector3(5,0.25,14),Color(0.18,0.2,0.23))
    make_box(plane,"LeftWall",Vector3(-2.5,1.5,0),Vector3(0.2,3,14),Color(0.72,0.75,0.78))
    make_box(plane,"RightWall",Vector3(2.5,1.5,0),Vector3(0.2,3,14),Color(0.72,0.75,0.78))
    make_box(plane,"Roof",Vector3(0,3,0),Vector3(5,0.2,14),Color(0.65,0.68,0.72))
    make_box(plane,"Dashboard",Vector3(0,1.05,-5.6),Vector3(4.8,1.6,0.8),Color(0.06,0.07,0.08))
    for x in [-1.7,-1.0,-0.3,0.4,1.1,1.8]:
        make_button(Vector3(x,1.35,-5.15))
    player = CharacterBody3D.new()
    player.position = Vector3(0,1.15,-3.8)
    plane.add_child(player)
    camera = Camera3D.new()
    camera.position = Vector3(0,0.65,0)
    player.add_child(camera)

func make_button(pos: Vector3):
    var b = make_box(plane,"CockpitButton",pos,Vector3(0.35,0.35,0.12),Color(0.8,0.12,0.08))
    b.set_meta("interactive",true)

func build_hud():
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(24,20)
    hud.add_theme_font_size_override("font_size",22)
    layer.add_child(hud)
    hint = Label.new()
    hint.position = Vector2(260,630)
    hint.size = Vector2(760,60)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size",24)
    layer.add_child(hint)
    windshield_dirt = ColorRect.new()
    windshield_dirt.position = Vector2(0,0)
    windshield_dirt.size = Vector2(1280,720)
    windshield_dirt.color = Color(0.32,0.24,0.1,0)
    windshield_dirt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(windshield_dirt)
    var cross = Label.new()
    cross.text = "+"
    cross.position = Vector2(635,350)
    cross.add_theme_font_size_override("font_size",24)
    layer.add_child(cross)

func _process(delta):
    if engine_on:
        fuel = max(0.0, fuel - delta * (0.015 + throttle * 0.04))
        if fuel <= 0: engine_on = false
    if seated:
        if Input.is_action_pressed("throttle_up"): throttle = min(1.0, throttle + delta*0.4)
        if Input.is_action_pressed("throttle_down"): throttle = max(0.0, throttle - delta*0.4)
        speed = move_toward(speed, throttle * 210.0 if engine_on else 0.0, delta*18.0)
        plane.translate(Vector3(0,0,-speed*delta*0.08))
        if speed > 90:
            if Input.is_action_pressed("pitch_up"): altitude += delta*35
            if Input.is_action_pressed("pitch_down"): altitude = max(0,altitude-delta*35)
            plane.position.y = 1.2 + altitude
        if Input.is_action_pressed("roll_left"): plane.rotation.z = lerp(plane.rotation.z,0.25,delta)
        elif Input.is_action_pressed("roll_right"): plane.rotation.z = lerp(plane.rotation.z,-0.25,delta)
        else: plane.rotation.z = lerp(plane.rotation.z,0.0,delta*2)
    else:
        var v = Input.get_vector("move_left","move_right","move_forward","move_back")
        player.velocity = (player.transform.basis * Vector3(v.x,0,v.y))*3.5
        player.move_and_slide()
    windshield_dirt.color.a = min(0.34, windshield_dirt.color.a + delta*0.0015)
    if wipers_on: windshield_dirt.color.a = max(0.0, windshield_dirt.color.a-delta*0.3)
    hud.text = "ТОПЛИВО: %d%%   СКОРОСТЬ: %d   ВЫСОТА: %d м\nДВИГАТЕЛЬ: %s   ДВОРНИКИ: %s" % [fuel,speed,altitude,"ВКЛ" if engine_on else "ВЫКЛ","ВКЛ" if wipers_on else "ВЫКЛ"]
    if Input.is_action_just_pressed("interact"): interact()

func interact():
    if tutorial_step == 0:
        engine_on = true
        tutorial_step = 1
        show_tutorial("Двигатель запущен! Стрелка ↑ — увеличить тягу.")
    elif tutorial_step == 1 and speed > 20:
        tutorial_step = 2
        show_tutorial("Разгоняйся. После 90 км/ч удерживай S, чтобы поднять нос.")
    else:
        wipers_on = !wipers_on

func show_tutorial(text: String):
    hint.text = text

func _input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x*0.002)
        camera.rotation.x = clamp(camera.rotation.x-event.relative.y*0.002,-1.2,1.2)
    if event is InputEventKey and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
