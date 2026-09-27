extends CanvasLayer

var game: Node
var left_touch := -1
var throttle_touch := -1
var look_touch := -1
var left_axis := Vector2.ZERO
var throttle_axis := 0.0
var left_center := Vector2.ZERO
var throttle_center := Vector2.ZERO
var left_base: ColorRect
var left_knob: ColorRect
var throttle_base: ColorRect
var throttle_knob: ColorRect

const JOYSTICK_RADIUS := 85.0

func _ready():
    game = get_parent()
    layer = 8
    build_controls()
    call_deferred("hide_legacy_flight_buttons")

func panel(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
    var r := ColorRect.new()
    r.position = pos
    r.size = size
    r.color = color
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(r)
    return r

func label(text_value: String, pos: Vector2, size: Vector2, font_size := 18) -> Label:
    var l := Label.new()
    l.text = text_value
    l.position = pos
    l.size = size
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size",font_size)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(l)
    return l

func build_controls():
    left_center = Vector2(145,560)
    throttle_center = Vector2(1160,530)
    left_base = panel(left_center-Vector2(90,90),Vector2(180,180),Color(0.05,0.06,0.08,0.38))
    left_knob = panel(left_center-Vector2(32,32),Vector2(64,64),Color(0.85,0.88,0.92,0.65))
    label("ШТУРВАЛ / ХОДЬБА",Vector2(45,655),Vector2(205,35),16)
    throttle_base = panel(Vector2(1120,390),Vector2(80,250),Color(0.05,0.06,0.08,0.38))
    throttle_knob = panel(Vector2(1128,514),Vector2(64,32),Color(0.92,0.72,0.16,0.8))
    label("ТЯГА",Vector2(1100,650),Vector2(120,30),16)
    label("100",Vector2(1210,385),Vector2(55,30),14)
    label("0",Vector2(1210,615),Vector2(55,30),14)

func hide_legacy_flight_buttons():
    await get_tree().process_frame
    for node in game.find_children("*","Button",true,false):
        if node.text in ["◀","▶","ТЯГА +","ТЯГА -"]:
            node.visible = false

func _process(delta):
    if game == null or game.get("game_over"):
        release_actions()
        return
    if game.get("seated"):
        Input.action_release("move_forward")
        Input.action_release("move_back")
        Input.action_release("move_left")
        Input.action_release("move_right")
        if abs(left_axis.x) > 0.08 and game.has_method("steer"):
            game.call("steer",left_axis.x*delta*3.2)
        if left_axis.y < -0.18:
            Input.action_press("pitch_up",abs(left_axis.y))
            Input.action_release("pitch_down")
        elif left_axis.y > 0.18:
            Input.action_press("pitch_down",abs(left_axis.y))
            Input.action_release("pitch_up")
        else:
            Input.action_release("pitch_up")
            Input.action_release("pitch_down")
        if throttle_touch >= 0:
            game.set("throttle",clamp(throttle_axis,0.0,1.0))
    else:
        Input.action_release("pitch_up")
        Input.action_release("pitch_down")
        set_walk_action("move_left",left_axis.x < -0.22,abs(left_axis.x))
        set_walk_action("move_right",left_axis.x > 0.22,abs(left_axis.x))
        set_walk_action("move_forward",left_axis.y < -0.22,abs(left_axis.y))
        set_walk_action("move_back",left_axis.y > 0.22,abs(left_axis.y))
    update_visuals()

func set_walk_action(action: String, pressed: bool, strength: float):
    if pressed: Input.action_press(action,strength)
    else: Input.action_release(action)

func release_actions():
    for a in ["pitch_up","pitch_down","move_left","move_right","move_forward","move_back"]:
        Input.action_release(a)

func update_visuals():
    left_knob.position = left_center + left_axis*JOYSTICK_RADIUS - left_knob.size*0.5
    var y: float = lerp(608.0,398.0,clamp(float(game.get("throttle")),0.0,1.0)) if game else 514.0
    throttle_knob.position = Vector2(1128,y)

func _unhandled_input(event):
    if event is InputEventScreenTouch:
        if event.pressed: begin_touch(event.index,event.position)
        else: end_touch(event.index)
    elif event is InputEventScreenDrag:
        update_touch(event.index,event.position,event.relative)

func begin_touch(index: int, pos: Vector2):
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if pos.x < viewport_size.x*0.38 and pos.y > viewport_size.y*0.42 and left_touch < 0:
        left_touch = index
        update_left(pos)
    elif pos.x > viewport_size.x*0.76 and pos.y > viewport_size.y*0.34 and throttle_touch < 0:
        throttle_touch = index
        update_throttle(pos)
    elif look_touch < 0:
        look_touch = index

func update_touch(index: int, pos: Vector2, relative: Vector2):
    if index == left_touch:
        update_left(pos)
    elif index == throttle_touch:
        update_throttle(pos)
    elif index == look_touch:
        rotate_view(relative)

func end_touch(index: int):
    if index == left_touch:
        left_touch = -1
        left_axis = Vector2.ZERO
    elif index == throttle_touch:
        throttle_touch = -1
    elif index == look_touch:
        look_touch = -1

func update_left(pos: Vector2):
    var offset: Vector2 = pos-left_center
    if offset.length() > JOYSTICK_RADIUS:
        offset = offset.normalized()*JOYSTICK_RADIUS
    left_axis = offset/JOYSTICK_RADIUS

func update_throttle(pos: Vector2):
    throttle_axis = clamp(1.0-(pos.y-390.0)/250.0,0.0,1.0)

func rotate_view(relative: Vector2):
    var p = game.get("player")
    var c = game.get("camera")
    if p != null:
        p.rotate_y(-relative.x*0.004)
    if c != null:
        c.rotation.x = clamp(c.rotation.x-relative.y*0.004,-1.2,1.2)
