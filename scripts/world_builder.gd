extends Node

var game: Node
var plane: Node3D
var cabin_light: OmniLight3D
var door: Node3D
var door_open := false
var gear_down := true
var fans: Array[Node3D] = []
var service_car: Node3D
var car_time := 0.0

func _ready():
    game = get_parent()
    call_deferred("setup")

func setup():
    await get_tree().process_frame
    plane = game.get("plane")
    if plane == null:
        await get_tree().process_frame
        plane = game.get("plane")
    if plane == null: return
    build_cabin()
    build_cockpit_controls()
    build_airport()
    build_engine_fans()

func add_label(parent: Node3D, text_value: String, pos: Vector3, size := 34):
    var l := Label3D.new()
    l.text = text_value
    l.position = pos
    l.font_size = size
    l.outline_size = 8
    l.pixel_size = 0.0025
    parent.add_child(l)
    return l

func build_cabin():
    # Galley
    game.box(plane,"GalleyLeft",Vector3(-1.85,1.05,5.7),Vector3(1.0,2.1,1.2),Color(0.74,0.76,0.78))
    game.box(plane,"GalleyRight",Vector3(1.85,1.05,5.7),Vector3(1.0,2.1,1.2),Color(0.74,0.76,0.78))
    game.box(plane,"GalleyShelf",Vector3(0,2.35,5.75),Vector3(3.5,0.25,1.0),Color(0.34,0.36,0.39))
    add_label(plane,"КУХНЯ",Vector3(0,2.55,5.15),28)
    # Small toilet compartment
    game.box(plane,"ToiletWall",Vector3(1.0,1.45,6.9),Vector3(0.15,2.9,2.0),Color(0.68,0.7,0.73))
    game.box(plane,"ToiletBack",Vector3(1.75,1.45,7.8),Vector3(1.65,2.9,0.15),Color(0.68,0.7,0.73))
    game.box(plane,"ToiletSeat",Vector3(1.75,0.45,7.15),Vector3(0.75,0.5,0.75),Color(0.9,0.9,0.88))
    add_label(plane,"WC",Vector3(1.55,2.3,6.0),28)
    # Side exit door - visual/interactive panel
    door = Node3D.new()
    door.name = "CabinDoorPivot"
    door.position = Vector3(-2.35,1.45,4.8)
    plane.add_child(door)
    var door_body = game.box(door,"CabinDoor",Vector3.ZERO,Vector3(0.18,2.65,1.45),Color(0.82,0.84,0.86))
    door_body.add_to_group("cockpit_action")
    door_body.set_meta("action","door")
    add_label(door,"ДВЕРЬ",Vector3(0.12,0.45,0),24)
    # Cabin light
    cabin_light = OmniLight3D.new()
    cabin_light.position = Vector3(0,2.55,1.5)
    cabin_light.omni_range = 11.0
    cabin_light.light_energy = 1.8
    cabin_light.visible = false
    plane.add_child(cabin_light)
    # Extra storage cabinets and luggage bins
    for z in [-2.0,0.0,2.0,4.0]:
        game.box(plane,"BinL",Vector3(-2.1,2.45,z),Vector3(0.65,0.55,1.45),Color(0.86,0.87,0.88))
        game.box(plane,"BinR",Vector3(2.1,2.45,z),Vector3(0.65,0.55,1.45),Color(0.86,0.87,0.88))

func make_button(name: String, title: String, pos: Vector3, color: Color, action: String):
    var b = game.box(plane,name,pos,Vector3(0.48,0.28,0.18),color)
    b.add_to_group("cockpit_action")
    b.set_meta("action",action)
    add_label(b,title,Vector3(0,0.26,0),20)

func build_cockpit_controls():
    make_button("EngineSwitch","ENG",Vector3(-1.65,1.6,-5.1),Color(0.82,0.18,0.12),"engine")
    make_button("GearSwitch","GEAR",Vector3(-1.0,1.6,-5.1),Color(0.18,0.55,0.2),"gear")
    make_button("LightSwitch","LIGHT",Vector3(-0.35,1.6,-5.1),Color(0.95,0.72,0.15),"light")
    make_button("DeiceSwitch","ICE",Vector3(0.35,1.6,-5.1),Color(0.12,0.55,0.85),"deice")
    make_button("WiperReset","WIPER",Vector3(1.0,1.6,-5.1),Color(0.35,0.38,0.42),"wiper_reset")
    make_button("MysterySwitch","???",Vector3(1.65,1.6,-5.1),Color(0.65,0.18,0.72),"funny")

func build_airport():
    # Apron and simple fictional terminal.
    game.box(game,"Apron",Vector3(-42,-0.52,115),Vector3(46,0.12,95),Color(0.28,0.29,0.31))
    game.box(game,"Terminal",Vector3(-58,5.0,100),Vector3(24,11,55),Color(0.62,0.68,0.73))
    game.box(game,"TerminalGlass",Vector3(-45.8,5.2,100),Vector3(0.3,7.0,43),Color(0.18,0.48,0.66))
    game.box(game,"TowerBase",Vector3(48,6,105),Vector3(9,13,9),Color(0.55,0.57,0.6))
    game.box(game,"TowerCab",Vector3(48,13.5,105),Vector3(13,3,13),Color(0.16,0.4,0.55))
    game.box(game,"Hangar",Vector3(55,7,35),Vector3(32,15,42),Color(0.43,0.45,0.47))
    # Runway edge lights.
    for z in range(-220,221,20):
        for x in [-18.0,18.0]:
            var lamp := OmniLight3D.new()
            lamp.position = Vector3(x,0.15,z)
            lamp.omni_range = 5.0
            lamp.light_energy = 1.6
            lamp.light_color = Color(0.75,0.88,1.0)
            game.add_child(lamp)
            game.box(game,"RunwayLamp",Vector3(x,-0.05,z),Vector3(0.25,0.35,0.25),Color(0.8,0.9,1.0))
    # Moving service vehicle.
    service_car = Node3D.new()
    service_car.position = Vector3(-28,0.2,145)
    game.add_child(service_car)
    game.box(service_car,"ServiceVan",Vector3.ZERO,Vector3(3.4,1.7,5.0),Color(0.96,0.72,0.08))
    game.box(service_car,"VanCab",Vector3(0,1.2,-1.0),Vector3(3.0,1.1,2.0),Color(0.9,0.92,0.94))

func build_engine_fans():
    for x in [-5.2,5.2]:
        var fan := Node3D.new()
        fan.position = Vector3(x,-0.45,-1.65)
        plane.add_child(fan)
        for angle in [0.0,60.0,120.0]:
            var blade = game.box(fan,"FanBlade",Vector3.ZERO,Vector3(1.25,0.08,0.15),Color(0.06,0.07,0.08))
            blade.rotation_degrees.z = angle
        fans.append(fan)

func _process(delta):
    if game == null: return
    if bool(game.get("engine_on")):
        var rpm := 5.0+float(game.get("throttle"))*24.0
        for f in fans: f.rotate_z(delta*rpm)
    if service_car:
        car_time += delta
        service_car.position.z = 120.0+sin(car_time*0.25)*55.0

func _unhandled_input(event):
    var pos := Vector2.ZERO
    var pressed := false
    if event is InputEventScreenTouch and event.pressed:
        pos = event.position
        pressed = true
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        pos = event.position
        pressed = true
    if not pressed: return
    var camera := get_viewport().get_camera_3d()
    if camera == null: return
    var from := camera.project_ray_origin(pos)
    var query := PhysicsRayQueryParameters3D.create(from,from+camera.project_ray_normal(pos)*18.0)
    var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty(): return
    var collider = hit.get("collider")
    if collider is Node and collider.is_in_group("cockpit_action"):
        run_action(String(collider.get_meta("action","")))
        get_viewport().set_input_as_handled()

func run_action(action: String):
    var audio = game.get("audio_manager")
    if audio and audio.has_method("one_shot"): audio.call("one_shot","click",-4.0)
    match action:
        "engine":
            if bool(game.get("engine_on")):
                game.set("engine_on",false)
                game.set("throttle",0.0)
                game.call("show_hint","Ты выключил двигатель. Очень смелое решение.")
            elif float(game.get("fuel")) > 0.0:
                game.set("engine_on",true)
                game.call("show_hint","Двигатель запущен с панели.")
        "gear":
            gear_down = not gear_down
            for n in ["GearL","GearR","NoseGear"]:
                var g = plane.get_node_or_null(n)
                if g: g.visible = gear_down
            game.call("show_hint","Шасси выпущено." if gear_down else "Шасси убрано.")
            notify_event("gear")
        "light":
            cabin_light.visible = not cabin_light.visible
            game.call("show_hint","Свет в салоне включён." if cabin_light.visible else "Свет в салоне выключен.")
        "deice":
            notify_event("deice")
            game.call("show_hint","Обогрев крыла включён. Лёд начинает сходить.")
        "wiper_reset":
            notify_event("wiper_reset")
            game.set("wipers_on",true)
            game.call("show_hint","Дворники перезапущены.")
        "door":
            if float(game.get("altitude")) > 3.0:
                game.call("show_hint","Открывать дверь в воздухе — всё-таки плохая идея.")
            else:
                door_open = not door_open
                door.rotation_degrees.z = -82.0 if door_open else 0.0
                game.call("show_hint","Дверь открыта." if door_open else "Дверь закрыта.")
        "funny":
            var phrases := ["Кнопка сказала: ПИК. Полезность неизвестна.","В салоне на секунду стало подозрительно уютно.","Где-то в самолёте включился совершенно ненужный зелёный огонёк.","Поздравляем: ты нажал секретную кнопку. Ничего не произошло. Наверное."]
            game.call("show_hint",phrases.pick_random())

func notify_event(action: String):
    var manager = game.get_node_or_null("EventManager")
    if manager and manager.has_method("cockpit_action"):
        manager.call("cockpit_action",action)
