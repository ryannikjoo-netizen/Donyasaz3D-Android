extends Node3D

var camera: Camera3D
var world: Node3D
var ui: CanvasLayer
var info: Label
var tool := "grass"
var mode := "build"
var playing := false
var actors: Array[Node3D] = []
var chosen: Node3D
var yaw := 0.7
var pitch := -0.65
var distance := 17.0
var touch_origin := Vector2.ZERO

func _ready():
    world = Node3D.new()
    add_child(world)
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#9bd8f4")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color.WHITE
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -35, 0)
    sun.shadow_enabled = true
    add_child(sun)
    var floor = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(24, 24)
    floor.mesh = plane
    floor.material_override = material(Color("#69b85b"))
    world.add_child(floor)
    for i in range(-12, 13):
        line(Vector3(i, 0.01, -12), Vector3(i, 0.01, 12))
        line(Vector3(-12, 0.01, i), Vector3(12, 0.01, i))
    camera = Camera3D.new()
    camera.current = true
    add_child(camera)
    build_ui()
    update_camera()

func material(c: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    return m

func line(a: Vector3, b: Vector3):
    var im = ImmediateMesh.new()
    im.surface_begin(Mesh.PRIMITIVE_LINES, material(Color("#a5d48d")))
    im.surface_add_vertex(a)
    im.surface_add_vertex(b)
    im.surface_end()
    var mi = MeshInstance3D.new()
    mi.mesh = im
    world.add_child(mi)

func update_camera():
    var target = chosen.global_position if chosen else Vector3.ZERO
    camera.position = target + Vector3(sin(yaw)*cos(pitch), -sin(pitch), cos(yaw)*cos(pitch))*distance
    camera.look_at(target, Vector3.UP)

func build_ui():
    ui = CanvasLayer.new()
    add_child(ui)
    var top = PanelContainer.new()
    top.anchor_right = 1.0
    top.offset_bottom = 52
    top.add_theme_stylebox_override("panel", panel_style())
    ui.add_child(top)
    var row = HBoxContainer.new()
    top.add_child(row)
    var title = Label.new()
    title.text = "  🌍 دنیاساز سه‌بعدی"
    title.add_theme_font_size_override("font_size", 22)
    row.add_child(title)
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    button(row, "راهنما", help)

    var bottom = PanelContainer.new()
    bottom.anchor_top = 1.0
    bottom.anchor_right = 1.0
    bottom.anchor_bottom = 1.0
    bottom.offset_top = -158
    bottom.add_theme_stylebox_override("panel", panel_style())
    ui.add_child(bottom)
    var col = VBoxContainer.new()
    bottom.add_child(col)
    var tabs = HBoxContainer.new()
    col.add_child(tabs)
    button(tabs, "ساخت دنیا", func(): set_mode("build"))
    button(tabs, "رفتارها", func(): set_mode("logic"))
    button(tabs, "بازی", func(): set_mode("play"))
    var build = HBoxContainer.new()
    build.name = "BuildTools"
    col.add_child(build)
    for pair in [["🌱 زمین","grass"],["🌳 درخت","tree"],["🧍 قهرمان","hero"],["🪨 سنگ","rock"],["🟡 سکه","coin"],["پاک‌کن","erase"]]:
        button(build, pair[0], func(): choose_tool(pair[1]))
    var logic = HBoxContainer.new()
    logic.name = "LogicTools"
    logic.visible = false
    col.add_child(logic)
    button(logic, "🚶 حرکت خودکار", func(): set_rule("wander"))
    button(logic, "⬆ پرش", func(): set_rule("jump"))
    button(logic, "🌀 چرخش", func(): set_rule("spin"))
    var actions = HBoxContainer.new()
    col.add_child(actions)
    button(actions, "پاک‌کردن دنیا", clear_world)
    button(actions, "▶ شروع / توقف", toggle_play)
    info = Label.new()
    info.text = "ابزار را انتخاب کن و روی زمین لمس کن."
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(info)

func panel_style():
    var s = StyleBoxFlat.new()
    s.bg_color = Color("#172a3bf2")
    s.corner_radius_top_left = 10
    s.corner_radius_top_right = 10
    return s

func button(parent: Node, caption: String, action: Callable):
    var b = Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(95, 40)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(action)
    parent.add_child(b)

func set_mode(value: String):
    mode = value
    var col = ui.get_child(1).get_child(0)
    col.get_node("BuildTools").visible = mode == "build"
    col.get_node("LogicTools").visible = mode == "logic"
    info.text = "روی قهرمان بزن و بعد رفتارش را انتخاب کن." if mode == "logic" else ("در حالت بازی قهرمان را با لمس جابه‌جا کن." if mode == "play" else "ابزار را انتخاب کن و روی زمین بزن.")

func choose_tool(value: String):
    tool = value
    info.text = "ابزار انتخاب شد: " + value

func set_rule(value: String):
    if chosen == null:
        info.text = "اول قهرمان را در زمین انتخاب کن."
    else:
        chosen.set_meta("rule", value)
        info.text = "رفتار ثبت شد: " + value

func toggle_play():
    playing = !playing
    set_mode("play" if playing else "build")
    info.text = "بازی شروع شد!" if playing else "حالت ساخت فعال شد."

func clear_world():
    for a in actors:
        a.queue_free()
    actors.clear()
    chosen = null
    info.text = "دنیا پاک شد."

func add_mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, scale_value: Vector3, color: Color):
    var m = MeshInstance3D.new()
    m.mesh = mesh
    m.position = pos
    m.scale = scale_value
    m.material_override = material(color)
    parent.add_child(m)

func place(kind: String, pos: Vector3):
    var root = Node3D.new()
    root.position = pos
    root.set_meta("kind", kind)
    world.add_child(root)
    if kind == "tree":
        add_mesh(root, CylinderMesh.new(), Vector3(0,.42,0), Vector3(.3,.85,.3), Color("#80502b"))
        for i in range(3):
            add_mesh(root, SphereMesh.new(), Vector3(0,1.0+i*.32,0), Vector3(1.0-i*.15,.8,1.0-i*.15), Color("#238348"))
    elif kind == "hero":
        add_mesh(root, CapsuleMesh.new(), Vector3(0,.62,0), Vector3(.7,.9,.7), Color("#287de0"))
        add_mesh(root, SphereMesh.new(), Vector3(0,1.25,0), Vector3(.48,.48,.48), Color("#ffd1a1"))
        chosen = root
    elif kind == "rock":
        add_mesh(root, SphereMesh.new(), Vector3(0,.3,0), Vector3(1.0,.65,.9), Color("#7c8791"))
    elif kind == "coin":
        add_mesh(root, TorusMesh.new(), Vector3(0,.65,0), Vector3(.6,.6,.6), Color("#ffcf35"))
    else:
        add_mesh(root, BoxMesh.new(), Vector3(0,.03,0), Vector3(.96,.08,.96), Color("#75c65c"))
    actors.append(root)

func ground_point(screen: Vector2):
    var origin = camera.project_ray_origin(screen)
    var dir = camera.project_ray_normal(screen)
    if abs(dir.y) < .001:
        return null
    var t = -origin.y / dir.y
    if t < 0:
        return null
    return origin + dir*t

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_origin = event.position
        else:
            var delta = event.position - touch_origin
            if delta.length() > 35:
                yaw -= delta.x*.008
                pitch = clamp(pitch + delta.y*.006, -.25, -1.25)
                update_camera()
            else:
                handle_tap(event.position)
    elif event is InputEventMouseButton and event.pressed:
        handle_tap(event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        yaw -= event.relative.x*.006
        pitch = clamp(pitch + event.relative.y*.005, -.25, -1.25)
        update_camera()

func handle_tap(screen: Vector2):
    var size = get_viewport().get_visible_rect().size
    if screen.y < 55 or screen.y > size.y-165:
        return
    var p = ground_point(screen)
    if p == null:
        return
    var pos = Vector3(round(p.x), 0, round(p.z))
    if mode == "build" and not playing:
        if tool == "erase":
            erase_near(pos)
        else:
            place(tool, pos)
    elif mode == "logic":
        var best = 1.5
        for a in actors:
            if a.get_meta("kind") == "hero":
                var d = Vector2(a.position.x,a.position.z).distance_to(Vector2(pos.x,pos.z))
                if d < best:
                    best = d
                    chosen = a
        if chosen:
            info.text = "قهرمان انتخاب شد؛ حالا یک رفتار بده."

func erase_near(pos: Vector3):
    var best: Node3D
    var dmin = .8
    for a in actors:
        var d = Vector2(a.position.x,a.position.z).distance_to(Vector2(pos.x,pos.z))
        if d < dmin:
            best = a
            dmin = d
    if best:
        actors.erase(best)
        if chosen == best:
            chosen = null
        best.queue_free()

func help():
    info.text = "ابزار را انتخاب کن؛ با کشیدن انگشت دوربین می‌چرخد. قهرمان را بساز و برایش رفتار تعیین کن."

func _process(delta):
    if not playing:
        return
    for a in actors:
        var rule = a.get_meta("rule", "")
        if rule == "spin":
            a.rotate_y(delta*1.8)
        elif rule == "jump" and a.get_meta("kind") == "hero":
            var timer = float(a.get_meta("timer",0.0))+delta
            a.set_meta("timer",timer)
            a.position.y = .15+abs(sin(timer*4.0))*.5
        elif rule == "wander" and a.get_meta("kind") == "hero":
            var timer = float(a.get_meta("timer",0.0))+delta
            a.set_meta("timer",timer)
            if timer > 1.2:
                a.set_meta("timer",0.0)
                a.position.x = clamp(a.position.x+randf_range(-1,1),-10,10)
                a.position.z = clamp(a.position.z+randf_range(-1,1),-10,10)
