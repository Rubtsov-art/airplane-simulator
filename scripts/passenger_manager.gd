extends Node

var game: Node
var passengers: Array[StaticBody3D] = []
var active_passenger: StaticBody3D
var concern_timer := 9.0

var concerns := [
    "ЭТО НОРМАЛЬНО?!",
    "МЫ ТОЧНО НЕ ПАДАЕМ?",
    "ПОЧЕМУ САМОЛЁТ ТАК ТРЯСЁТ?",
    "Я СЛЫШАЛ КАКОЙ-ТО ХРУСТ!",
    "А ПИЛОТ ДАВНО ЭТОМУ УЧИЛСЯ?",
    "ПОЧЕМУ ТАМ ЧТО-ТО МИГАЕТ?!"
]

var silly_reassurances := [
    "Всё нормально. Я вчера смотрел инструкцию.",
    "Не волнуйтесь, самолёт тоже старается.",
    "Этот звук? Так он просто думает.",
    "По плану мы почти точно летим правильно.",
    "Главное — не смотреть в окно слишком внимательно.",
    "Я нажал зелёную кнопку. Зелёный — хороший цвет.",
    "Спокойно, у нас ещё очень много топлива. Наверное.",
    "Если что, я умею очень уверенно выглядеть.",
    "Это не тряска, это бесплатный массаж.",
    "Пока крылья на месте — всё прекрасно."
]

func _ready():
    game = get_parent()
    call_deferred("setup_passengers")

func setup_passengers():
    await get_tree().process_frame
    var plane: Node3D = game.get("plane")
    if plane == null:
        await get_tree().process_frame
        plane = game.get("plane")
    if plane == null:
        return

    var seats := [
        Vector3(-1.3, 0.85, -1.0),
        Vector3(1.3, 0.85, -1.0),
        Vector3(-1.3, 0.85, 1.0),
        Vector3(1.3, 0.85, 1.0),
        Vector3(-1.3, 0.85, 3.0),
        Vector3(1.3, 0.85, 3.0)
    ]
    for i in range(seats.size()):
        create_passenger(plane, seats[i], i)

func make_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    return mat

func create_passenger(plane: Node3D, pos: Vector3, index: int):
    var passenger := StaticBody3D.new()
    passenger.name = "Passenger%d" % (index + 1)
    passenger.position = pos
    passenger.add_to_group("passenger")
    passenger.set_meta("worried", false)
    plane.add_child(passenger)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.55
    collision.shape = capsule
    collision.position.y = 0.35
    passenger.add_child(collision)

    var torso := MeshInstance3D.new()
    var torso_mesh := BoxMesh.new()
    torso_mesh.size = Vector3(0.62, 0.78, 0.38)
    torso.mesh = torso_mesh
    var shirt_colors := [Color(0.18,0.42,0.78), Color(0.78,0.26,0.18), Color(0.15,0.58,0.32), Color(0.62,0.28,0.72), Color(0.85,0.58,0.12), Color(0.22,0.58,0.62)]
    torso.material_override = make_material(shirt_colors[index % shirt_colors.size()])
    torso.position = Vector3(0,0.38,0)
    passenger.add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.54
    head.mesh = head_mesh
    head.material_override = make_material(Color(0.91,0.72,0.56))
    head.position = Vector3(0,1.05,-0.03)
    passenger.add_child(head)

    for x in [-0.2, 0.2]:
        var leg := MeshInstance3D.new()
        var leg_mesh := BoxMesh.new()
        leg_mesh.size = Vector3(0.22,0.62,0.25)
        leg.mesh = leg_mesh
        leg.material_override = make_material(Color(0.12,0.15,0.2))
        leg.position = Vector3(x,-0.18,-0.24)
        leg.rotation_degrees.x = -25
        passenger.add_child(leg)

    var label := Label3D.new()
    label.name = "Concern"
    label.text = ""
    label.position = Vector3(0,1.65,0)
    label.font_size = 38
    label.outline_size = 10
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.visible = false
    passenger.add_child(label)
    passengers.append(passenger)

func _process(delta):
    if passengers.is_empty():
        return
    if not game.get("has_flown") or game.get("game_over"):
        return
    if active_passenger != null:
        return

    var danger_multiplier := 1.0
    if game.get("active_failure") != "" or game.get("raining"):
        danger_multiplier = 2.2
    concern_timer -= delta * danger_multiplier
    if concern_timer <= 0.0:
        worry_random_passenger()

func worry_random_passenger():
    if passengers.is_empty():
        return
    active_passenger = passengers.pick_random()
    active_passenger.set_meta("worried", true)
    var label: Label3D = active_passenger.get_node("Concern")
    label.text = concerns.pick_random()
    label.visible = true
    if game.has_method("show_hint"):
        game.call("show_hint", "Пассажир нервничает. Нажми на него, чтобы успокоить.")

func _unhandled_input(event):
    var screen_pos := Vector2.ZERO
    var pressed := false
    if event is InputEventScreenTouch and event.pressed:
        screen_pos = event.position
        pressed = true
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        screen_pos = event.position
        pressed = true
    if not pressed:
        return

    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var from := camera.project_ray_origin(screen_pos)
    var to := from + camera.project_ray_normal(screen_pos) * 30.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var collider = hit.get("collider")
    if collider is StaticBody3D and collider.is_in_group("passenger"):
        calm_passenger(collider)
        get_viewport().set_input_as_handled()

func calm_passenger(passenger: StaticBody3D):
    if passenger != active_passenger:
        if game.has_method("show_hint"):
            game.call("show_hint", "Этот пассажир пока удивительно спокоен.")
        return

    passenger.set_meta("worried", false)
    var phrase: String = silly_reassurances.pick_random()
    var label: Label3D = passenger.get_node("Concern")
    label.text = "...ЛАДНО."
    active_passenger = null
    concern_timer = randf_range(12.0, 24.0)

    var audio = game.get("audio_manager")
    if audio != null and audio.has_method("one_shot"):
        audio.call("one_shot", "click", -5.0)
    if game.has_method("show_hint"):
        game.call("show_hint", "ПИЛОТ: «%s»" % phrase)

    await get_tree().create_timer(2.0).timeout
    if is_instance_valid(label) and not passenger.get_meta("worried", false):
        label.visible = false
