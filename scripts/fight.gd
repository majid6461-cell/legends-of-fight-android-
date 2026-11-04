class_name Fight
extends Node3D
## A complete match: arena, two fighters, HUD, touch controls, AI and rounds.

signal finished(p1_won: bool)
signal quit_requested

var f1: Fighter
var f2: Fighter
var cam: Camera3D
var hud: CanvasLayer
var root_ui: Control
var bar1: ProgressBar
var bar2: ProgressBar
var en1: ProgressBar
var en2: ProgressBar
var lbl_time: Label
var lbl_banner: Label
var lbl_w1: Label
var lbl_w2: Label
var wins: Array = [0, 0]
var round_no: int = 1
var timer: float = 60.0
var phase: String = "intro"
var phase_t: float = 0.0
var fight_shown: bool = false
var touch_map: Dictionary = {}
var pads: Array = []
var prev_held: Dictionary = {1: {}, 2: {}}
var ai_t: float = 0.0
var ai_level: float = 0.5
var practice: bool = false
var two_player: bool = false
var stage_text: String = ""
var enemy_bonus: float = 0.0
var enemy_scale: float = 1.0
var finished_sent: bool = false


func _ready() -> void:
	practice = Game.mode == "practice"
	two_player = Game.mode == "local"
	if Game.mode == "tournament":
		ai_level = clampf(0.15 + float(Game.stage) * 0.09, 0.1, 0.98)
		enemy_bonus = float(Game.stage) * 5.0
		if Game.stage == 9:
			enemy_scale = 1.15
			enemy_bonus += 40.0
	else:
		var lv: Array = [0.2, 0.5, 0.85]
		ai_level = lv[Game.difficulty]
	var vp := get_viewport()
	if Game.gfx == 0:
		vp.scaling_3d_scale = 0.7
	elif Game.gfx == 2:
		vp.msaa_3d = Viewport.MSAA_2X
	_build_world()
	_build_fighters()
	_build_hud()
	_build_pads()
	Game.play_music(Game.env)
	_start_round()


func _exit_tree() -> void:
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = 1.0
		vp.msaa_3d = Viewport.MSAA_DISABLED


# ================================================================ world
func _mesh(m: Mesh, pos: Vector3, col: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.9
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _bx(size: Vector3, pos: Vector3, col: Color, emit: float = 0.0) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(b, pos, col, emit)


func _cy(rt: float, rb: float, h: float, pos: Vector3, col: Color, emit: float = 0.0) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 10
	return _mesh(c, pos, col, emit)


func _sp(r: float, pos: Vector3, col: Color, emit: float = 0.0) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 5
	return _mesh(s, pos, col, emit)


func _omni(pos: Vector3, col: Color, energy: float, rng: float) -> void:
	if Game.gfx == 0:
		return
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)


func _build_world() -> void:
	var e: Dictionary = Game.ENVS[Game.env]
	var we := WorldEnvironment.new()
	var en := Environment.new()
	var skm := ProceduralSkyMaterial.new()
	skm.sky_top_color = e.top
	skm.sky_horizon_color = e.hor
	skm.ground_horizon_color = e.hor
	skm.ground_bottom_color = Color(e.ground).darkened(0.4)
	var sky := Sky.new()
	sky.sky_material = skm
	en.background_mode = Environment.BG_SKY
	en.sky = sky
	en.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	en.ambient_light_color = e.amb
	en.ambient_light_energy = 1.0
	en.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if Game.gfx >= 1:
		en.fog_enabled = true
		en.fog_light_color = e.hor
		en.fog_density = 0.012
	we.environment = en
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_color = e.light
	sun.light_energy = 1.1
	sun.shadow_enabled = Game.gfx >= 1
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	# floor
	_bx(Vector3(30, 0.4, 12), Vector3(0, -0.2, -1), e.ground)
	_props(String(e.prop))
	var fx: String = e.fx
	if fx != "none":
		_particles(fx)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.position = Vector3(0, 2.1, 7.0)
	cam.far = 80.0
	add_child(cam)
	cam.current = true


func _props(kind: String) -> void:
	match kind:
		"street":
			var neon: Array = [Color("ff2bd6"), Color("22e4ff"), Color("ffe14d")]
			for i in range(-7, 8):
				var h: float = 3.0 + float((i * 7) % 5 + 5) * 0.6
				var x: float = float(i) * 2.4
				_bx(Vector3(2.2, h * 1.5, 2.0), Vector3(x, h * 0.75, -7.0), Color(0.07, 0.07, 0.14 + 0.02 * float(i % 3)))
				_bx(Vector3(1.9, 0.12, 0.1), Vector3(x, 2.0 + float(i % 4) * 1.2, -5.95), neon[abs(i) % 3], 2.5)
			_omni(Vector3(-5, 3, -3), Color("ff2bd6"), 2.5, 12.0)
			_omni(Vector3(5, 3, -3), Color("22e4ff"), 2.5, 12.0)
		"temple":
			for i in range(-3, 4):
				_cy(0.35, 0.35, 4.5, Vector3(float(i) * 3.2, 2.25, -4.0), Color("a8321f"))
			_bx(Vector3(24, 0.5, 3), Vector3(0, 4.6, -4.0), Color("3a2a22"))
			_bx(Vector3(26, 0.3, 4), Vector3(0, 5.0, -4.0), Color("5a2a20"))
			_bx(Vector3(30, 8, 0.5), Vector3(0, 4.0, -9.0), Color("d8c3a0"))
			for i in [-6, -2, 2, 6]:
				_sp(0.3, Vector3(float(i), 3.6, -3.0), Color("ff8a30"), 2.0)
				_omni(Vector3(float(i), 3.6, -3.0), Color("ff9a40"), 1.5, 7.0)
		"arena":
			for r in 4:
				_bx(Vector3(30, 1.0, 2.0), Vector3(0, 0.5 + float(r), -6.0 - float(r) * 2.0), Color(0.12 + 0.03 * float(r), 0.12, 0.2))
				for i in range(-7, 8, 2):
					_sp(0.18, Vector3(float(i) + float(r % 2), 1.3 + float(r), -5.0 - float(r) * 2.0), Color(0.8, 0.7, 0.5))
			for cx in [-7.0, 7.0]:
				_cy(0.12, 0.12, 2.0, Vector3(cx, 1.0, -3.0), Color("d02020"))
			_bx(Vector3(14, 0.06, 0.06), Vector3(0, 1.5, -3.0), Color("e8e8e8"))
			_bx(Vector3(14, 0.06, 0.06), Vector3(0, 0.9, -3.0), Color("d02020"))
			if Game.gfx >= 1:
				for sx in [-6.0, 0.0, 6.0]:
					var s := SpotLight3D.new()
					s.position = Vector3(sx, 9.0, 0.0)
					s.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
					s.light_energy = 3.0
					s.spot_range = 14.0
					s.spot_angle = 28.0
					add_child(s)
		"rooftop":
			_bx(Vector3(30, 1.0, 0.5), Vector3(0, 0.5, -3.5), Color("2c3036"))
			for i in range(-8, 9):
				var h: float = 6.0 + float((i * 5) % 7 + 7) * 1.3
				_bx(Vector3(2.4, h, 2.0), Vector3(float(i) * 3.0, -3.0 + h * 0.5, -14.0), Color(0.12, 0.13, 0.2))
				for w in 3:
					_bx(Vector3(0.3, 0.3, 0.05), Vector3(float(i) * 3.0, -1.0 + float(w) * 1.6, -12.95), Color("ffd070"), 1.5)
		"jungle":
			for i in range(-6, 7):
				var x: float = float(i) * 2.6 + float(i % 2) * 0.8
				var z: float = -5.0 - float(abs(i) % 3) * 1.6
				_cy(0.28, 0.4, 5.0, Vector3(x, 2.5, z), Color("5a3a22"))
				_sp(1.5, Vector3(x, 5.6, z), Color("1f6a2a"))
				_sp(1.1, Vector3(x + 0.8, 4.8, z + 0.4), Color("2a8a38"))
		"factory":
			_bx(Vector3(30, 10, 0.5), Vector3(0, 5.0, -8.0), Color("34302c"))
			for i in range(-3, 4):
				var pipe := _cy(0.3, 0.3, 28.0, Vector3(0, 2.0 + float(i + 3) * 0.9, -7.5), Color("6a5a4a"))
				pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			for i in [-5, 5]:
				_cy(0.9, 1.1, 10.0, Vector3(float(i), 5.0, -9.5), Color("4a3a30"))
				_bx(Vector3(1.4, 1.4, 1.4), Vector3(float(i) * 1.4, 0.7, -3.5), Color("8a5a30"))
			_omni(Vector3(0, 3, -4), Color("ff7a30"), 2.5, 14.0)
		"castle":
			_bx(Vector3(30, 6, 1.0), Vector3(0, 3.0, -6.0), Color("6a6a70"))
			for i in range(-7, 8):
				_bx(Vector3(1.0, 0.9, 1.0), Vector3(float(i) * 2.0, 6.4, -6.0), Color("6a6a70"))
			for i in [-5, 0, 5]:
				_bx(Vector3(1.2, 3.0, 0.1), Vector3(float(i), 3.5, -5.4), Color("902020"))
			for i in [-7, -2.5, 2.5, 7]:
				_sp(0.22, Vector3(float(i), 2.4, -5.3), Color("ffa040"), 3.0)
				_omni(Vector3(float(i), 2.4, -4.8), Color("ff9040"), 1.6, 6.0)
		"snow":
			for i in range(-7, 8):
				var x: float = float(i) * 2.4
				var z: float = -6.0 - float(abs(i) % 3) * 1.8
				_cy(0.18, 0.18, 1.2, Vector3(x, 0.6, z), Color("5a3a22"))
				for k in 3:
					_cy(0.0, 1.6 - float(k) * 0.35, 1.6, Vector3(x, 1.5 + float(k) * 1.0, z), Color("1f5a3a"))
			for i in range(-3, 4):
				_cy(0.0, 4.0, 7.0, Vector3(float(i) * 7.0, 3.5, -16.0), Color("aab8c8"))


func _particles(kind: String) -> void:
	var amounts: Array = [60, 160, 320]
	var p := CPUParticles3D.new()
	p.amount = amounts[Game.gfx]
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(11.0, 0.2, 5.0)
	p.position = Vector3(0, 8, -2)
	p.direction = Vector3(0, -1, 0)
	p.spread = 4.0
	var mesh: PrimitiveMesh
	var col: Color = Color.WHITE
	var glow: bool = false
	match kind:
		"rain":
			p.lifetime = 0.8
			p.gravity = Vector3(0, -30, 0)
			p.initial_velocity_min = 8.0
			p.initial_velocity_max = 10.0
			var b := BoxMesh.new()
			b.size = Vector3(0.02, 0.5, 0.02)
			mesh = b
			col = Color(0.7, 0.8, 1.0)
		"snow":
			p.lifetime = 6.0
			p.gravity = Vector3(0, -0.6, 0)
			p.initial_velocity_min = 0.5
			p.initial_velocity_max = 1.5
			p.spread = 25.0
			var s := SphereMesh.new()
			s.radius = 0.04
			s.height = 0.08
			s.radial_segments = 6
			s.rings = 3
			mesh = s
		"leaf":
			p.lifetime = 5.0
			p.gravity = Vector3(0.3, -0.8, 0)
			p.initial_velocity_min = 0.3
			p.initial_velocity_max = 1.0
			p.spread = 40.0
			var b2 := BoxMesh.new()
			b2.size = Vector3(0.1, 0.02, 0.06)
			mesh = b2
			col = Color("e8742a")
		"firefly":
			p.lifetime = 4.0
			p.position = Vector3(0, 0.8, -2)
			p.direction = Vector3(0, 1, 0)
			p.gravity = Vector3.ZERO
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.5
			p.spread = 180.0
			p.amount = int(p.amount / 3)
			var s2 := SphereMesh.new()
			s2.radius = 0.05
			s2.height = 0.1
			s2.radial_segments = 6
			s2.rings = 3
			mesh = s2
			col = Color("d8ff60")
			glow = true
		_:
			p.lifetime = 3.0
			p.position = Vector3(0, 0.2, -2)
			p.direction = Vector3(0, 1, 0)
			p.gravity = Vector3(0, 0.5, 0)
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 3.0
			p.spread = 30.0
			var s3 := SphereMesh.new()
			s3.radius = 0.04
			s3.height = 0.08
			s3.radial_segments = 6
			s3.rings = 3
			mesh = s3
			col = Color("ff8a30")
			glow = true
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow:
		m.emission_enabled = true
		m.emission = col
	mesh.material = m
	p.mesh = mesh
	p.preprocess = p.lifetime
	add_child(p)


# ================================================================ fighters
func _build_fighters() -> void:
	f1 = Fighter.new()
	f2 = Fighter.new()
	add_child(f1)
	add_child(f2)
	f1.setup(Game.FIGHTERS[Game.p1], 1)
	f2.setup(Game.FIGHTERS[Game.p2], 2, enemy_scale)
	f1.opp = f2
	f2.opp = f1
	f2.max_hp = 100.0 + enemy_bonus
	f1.position = Vector3(-2.2, 0, 0)
	f2.position = Vector3(2.2, 0, 0)


func _start_round() -> void:
	f1.reset_for_round(-2.2, 1)
	f2.reset_for_round(2.2, -1)
	f1.frozen = true
	f2.frozen = true
	phase = "intro"
	phase_t = 0.0
	fight_shown = false
	timer = 60.0
	if practice:
		lbl_banner.text = Game.t("practice")
	else:
		lbl_banner.text = stage_text + Game.t("round") + " " + str(round_no)
	lbl_banner.visible = true


# ================================================================ HUD
func _bar(col: Color, rtl: bool, ax: float, ox: float, oy: float, w: float, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 100.0
	b.value = 100.0
	if rtl:
		b.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(2)
	bg.border_color = Color(1, 1, 1, 0.7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	Game.place(b, ax, 0.0, ox, oy, w, h)
	root_ui.add_child(b)
	return b


func _hud_label(text: String, size: int, ax: float, ay: float, ox: float, oy: float, w: float, h: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.place(l, ax, ay, ox, oy, w, h)
	root_ui.add_child(l)
	return l


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.theme = Game.ui_theme
	hud.add_child(root_ui)
	bar1 = _bar(Color(0.9, 0.2, 0.2), false, 0.0, 30.0, 18.0, 480.0, 30.0)
	bar2 = _bar(Color(0.9, 0.2, 0.2), true, 1.0, -510.0, 18.0, 480.0, 30.0)
	en1 = _bar(Color(1.0, 0.8, 0.2), false, 0.0, 30.0, 54.0, 300.0, 14.0)
	en2 = _bar(Color(1.0, 0.8, 0.2), true, 1.0, -330.0, 54.0, 300.0, 14.0)
	_hud_label(Game.nm(Game.p1), 22, 0.0, 0.0, 30.0, 70.0, 300.0, 30.0)
	_hud_label(Game.nm(Game.p2) if not practice else Game.t("practice"), 22, 1.0, 0.0, -330.0, 70.0, 300.0, 30.0)
	lbl_time = _hud_label("60", 44, 0.5, 0.0, -50.0, 8.0, 100.0, 56.0)
	lbl_w1 = _hud_label("", 26, 0.0, 0.0, 340.0, 46.0, 120.0, 30.0)
	lbl_w2 = _hud_label("", 26, 1.0, 0.0, -460.0, 46.0, 120.0, 30.0)
	lbl_banner = _hud_label("", 72, 0.5, 0.4, -450.0, -70.0, 900.0, 140.0)
	var quit := Button.new()
	quit.text = Game.t("menu")
	quit.add_theme_font_size_override("font_size", 20)
	Game.place(quit, 0.5, 0.0, -55.0, 68.0, 110.0, 38.0)
	quit.pressed.connect(func(): quit_requested.emit())
	root_ui.add_child(quit)
	if practice:
		var hl := _hud_label(Game.t("practice_help"), 18, 0.5, 0.0, -380.0, 112.0, 760.0, 30.0)
		hl.add_theme_font_size_override("font_size", 18)


func _update_hud() -> void:
	bar1.max_value = f1.max_hp
	bar1.value = f1.hp
	bar2.max_value = f2.max_hp
	bar2.value = f2.hp
	en1.value = f1.energy
	en2.value = f2.energy
	lbl_time.text = "∞" if practice else str(maxi(0, int(ceil(timer))))
	if not practice:
		lbl_w1.text = "●".repeat(wins[0]) + "○".repeat(maxi(0, 2 - wins[0]))
		lbl_w2.text = "●".repeat(wins[1]) + "○".repeat(maxi(0, 2 - wins[1]))
	for p in pads:
		var down: bool = false
		for idx in touch_map:
			if touch_map[idx].node == p.node:
				down = true
		p.node.modulate = Color(1, 1, 1, 1.0 if down else 0.7)


# ================================================================ touch pads
func _add_pad(pn: int, key: String, ax: float, ox: float, oy: float, sz: float) -> void:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var colors: Dictionary = {
		"left": Color(0.9, 0.9, 1.0), "right": Color(0.9, 0.9, 1.0), "jump": Color(0.6, 1.0, 0.7),
		"punch": Color(1.0, 0.4, 0.35), "kick": Color(1.0, 0.65, 0.25), "block": Color(0.4, 0.7, 1.0),
		"special": Color(0.85, 0.5, 1.0)}
	var c: Color = colors[key]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.r, c.g, c.b, 0.22)
	sb.set_corner_radius_all(int(sz / 2.0))
	sb.set_border_width_all(4)
	sb.border_color = Color(c.r, c.g, c.b, 0.85)
	p.add_theme_stylebox_override("panel", sb)
	Game.place(p, ax, 1.0, ox, oy, sz, sz)
	var l := Label.new()
	l.text = Game.t("k_" + key)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 26 if sz > 110.0 else 20)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	p.add_child(l)
	root_ui.add_child(p)
	pads.append({"pid": pn, "key": key, "node": p})


func _build_pads() -> void:
	if two_player:
		for pn in [1, 2]:
			var ax: float = 0.0 if pn == 1 else 1.0
			var sh: float = 0.0 if pn == 1 else -490.0
			_add_pad(pn, "left", ax, 20.0 + sh, -120.0, 100.0)
			_add_pad(pn, "right", ax, 130.0 + sh, -120.0, 100.0)
			_add_pad(pn, "jump", ax, 75.0 + sh, -230.0, 100.0)
			_add_pad(pn, "punch", ax, 260.0 + sh, -120.0, 100.0)
			_add_pad(pn, "kick", ax, 370.0 + sh, -120.0, 100.0)
			_add_pad(pn, "block", ax, 260.0 + sh, -230.0, 100.0)
			_add_pad(pn, "special", ax, 370.0 + sh, -230.0, 100.0)
	else:
		_add_pad(1, "left", 0.0, 40.0, -150.0, 120.0)
		_add_pad(1, "right", 0.0, 180.0, -150.0, 120.0)
		_add_pad(1, "jump", 0.0, 110.0, -290.0, 120.0)
		_add_pad(1, "punch", 1.0, -290.0, -200.0, 120.0)
		_add_pad(1, "kick", 1.0, -150.0, -270.0, 120.0)
		_add_pad(1, "block", 1.0, -150.0, -130.0, 120.0)
		_add_pad(1, "special", 1.0, -290.0, -340.0, 120.0)


func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			_touch_down(st.index, st.position)
		else:
			touch_map.erase(st.index)
	elif ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		touch_map.erase(sd.index)
		_touch_down(sd.index, sd.position)


func _touch_down(idx: int, pos: Vector2) -> void:
	for p in pads:
		var n: Control = p.node
		if n.get_global_rect().grow(14.0).has_point(pos):
			touch_map[idx] = p
			return


func _read_input() -> void:
	var held: Dictionary = {1: {}, 2: {}}
	for idx in touch_map:
		var p: Dictionary = touch_map[idx]
		held[p.pid][p.key] = true
	var kb1: Dictionary = {"left": KEY_A, "right": KEY_D, "jump": KEY_W, "punch": KEY_F, "kick": KEY_G, "block": KEY_H, "special": KEY_T}
	var kb2: Dictionary = {"left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_UP, "punch": KEY_J, "kick": KEY_K, "block": KEY_L, "special": KEY_I}
	for k in kb1:
		if Input.is_key_pressed(kb1[k]):
			held[1][k] = true
	if two_player:
		for k in kb2:
			if Input.is_key_pressed(kb2[k]):
				held[2][k] = true
	_apply(f1, 1, held[1])
	if two_player:
		_apply(f2, 2, held[2])


func _apply(f: Fighter, pn: int, h: Dictionary) -> void:
	f.inp.left = h.has("left")
	f.inp.right = h.has("right")
	f.inp.block = h.has("block")
	for k in ["punch", "kick", "special", "jump"]:
		if h.has(k) and not prev_held[pn].has(k):
			f.press(k)
	prev_held[pn] = h


# ================================================================ AI
func _ai(delta: float) -> void:
	ai_t -= delta
	if ai_t > 0.0:
		return
	ai_t = lerpf(0.4, 0.09, ai_level) * randf_range(0.7, 1.3)
	var me: Fighter = f2
	var pl: Fighter = f1
	me.inp.left = false
	me.inp.right = false
	me.inp.block = false
	if practice:
		return
	if me.state == "hit" or me.state == "ko":
		return
	var dx: float = pl.position.x - me.position.x
	var dist: float = absf(dx)
	var toward: String = "right" if dx > 0.0 else "left"
	var away: String = "left" if dx > 0.0 else "right"
	var threat: bool = pl.state == "attack" and dist < 2.3
	if threat and randf() < 0.12 + 0.7 * ai_level:
		if randf() < 0.25 * ai_level:
			me.inp[away] = true
		me.inp.block = true
		return
	if dist > 1.6:
		me.inp[toward] = true
		if dist < 2.6 and me.energy >= 50.0 and randf() < 0.35 * ai_level:
			me.press("special")
		elif randf() < 0.05 * ai_level:
			me.press("jump")
		return
	var r: float = randf()
	if r < 0.35 + 0.5 * ai_level:
		if me.energy >= 50.0 and randf() < 0.25 * ai_level:
			me.press("special")
		else:
			me.press("punch" if randf() < 0.55 else "kick")
			if randf() < ai_level:
				ai_t = 0.16
	elif r < 0.6 + 0.25 * ai_level:
		me.inp[away] = true
	else:
		me.inp.block = randf() < 0.5


# ================================================================ flow
func _physics_process(delta: float) -> void:
	_read_input()
	match phase:
		"intro":
			phase_t += delta
			if phase_t > 1.5 and not fight_shown:
				fight_shown = true
				lbl_banner.text = Game.t("fight")
				Game.sfx("special")
			if phase_t > 2.1:
				phase = "fight"
				f1.frozen = false
				f2.frozen = false
				lbl_banner.visible = false
		"fight":
			if not practice:
				timer -= delta
			if not two_player:
				_ai(delta)
			_check_end()
		"over":
			phase_t += delta
			if phase_t > 2.4:
				_next_round()
	_update_hud()


func _check_end() -> void:
	if practice:
		if f2.hp < 30.0:
			f2.hp = f2.max_hp
		if f1.hp < 30.0:
			f1.hp = f1.max_hp
		f1.energy = minf(100.0, f1.energy + 0.15)
		return
	if f1.hp <= 0.0 or f2.hp <= 0.0 or timer <= 0.0:
		var w: int = 0
		if f1.hp <= 0.0 and f2.hp <= 0.0:
			w = 0
		elif f1.hp <= 0.0:
			w = 2
		elif f2.hp <= 0.0:
			w = 1
		else:
			var r1: float = f1.hp / f1.max_hp
			var r2: float = f2.hp / f2.max_hp
			if r1 > r2:
				w = 1
			elif r2 > r1:
				w = 2
		if w > 0:
			wins[w - 1] += 1
		if f1.hp <= 0.0 or f2.hp <= 0.0:
			lbl_banner.text = Game.t("ko")
		elif w == 0:
			lbl_banner.text = Game.t("draw")
		else:
			lbl_banner.text = Game.t("time_up")
		lbl_banner.visible = true
		phase = "over"
		phase_t = 0.0
		f1.frozen = true
		f2.frozen = true


func _next_round() -> void:
	if wins[0] >= 2 or wins[1] >= 2:
		if not finished_sent:
			finished_sent = true
			finished.emit(wins[0] > wins[1])
		return
	round_no += 1
	_start_round()


func _process(delta: float) -> void:
	if cam == null or f1 == null:
		return
	var mid: float = (f1.position.x + f2.position.x) * 0.5
	var dist: float = absf(f1.position.x - f2.position.x)
	var tz: float = 6.2 + clampf(dist * 0.45, 0.0, 3.5)
	var cp: Vector3 = cam.position
	cp.x = lerpf(cp.x, mid, minf(1.0, delta * 5.0))
	cp.z = lerpf(cp.z, tz, minf(1.0, delta * 3.0))
	cp.y = 2.1
	cam.position = cp
	cam.look_at(Vector3(cp.x, 1.1, 0.0))
