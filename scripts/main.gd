extends Node
## Menu flow: main menu, selection screens, settings, help, results.

var ui: CanvasLayer
var bg: ColorRect
var cur: Control = null
var fight: Fight = null
var sel: int = 0
var pick_pid: int = 1
var pick_flow: String = "single"
var preview_fighter: Fighter = null
var stat_bars: Array = []
var cards: Array = []
var lbl_name: Label
var lbl_style: Label
var lbl_lock: Label
var confirm_btn: Button
var last_gain: int = 0


func _ready() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var tw := create_tween().set_loops()
	tw.tween_property(bg, "color", Color(0.14, 0.05, 0.12), 5.0)
	tw.tween_property(bg, "color", Color(0.04, 0.1, 0.16), 5.0)
	tw.tween_property(bg, "color", Color(0.05, 0.05, 0.14), 5.0)
	Game.play_music(8)
	show_menu()


# ------------------------------------------------------------------ helpers
func _clear() -> void:
	if cur:
		cur.queue_free()
		cur = null
	preview_fighter = null


func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.theme = Game.ui_theme
	ui.add_child(c)
	return c


func _lbl(parent: Node, text: String, size: int = 26, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func _style(b: Button, col: Color, border: bool = false) -> void:
	var variants: Dictionary = {
		"normal": col, "hover": col.lightened(0.15), "pressed": col.darkened(0.2),
		"disabled": col.darkened(0.55), "focus": col}
	for k in variants:
		var sb := StyleBoxFlat.new()
		sb.bg_color = variants[k]
		sb.set_corner_radius_all(14)
		sb.set_border_width_all(4 if border else 2)
		sb.border_color = Color.WHITE if border else Color(1, 1, 1, 0.35)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		b.add_theme_stylebox_override(k, sb)


func _btn(parent: Node, text: String, cb: Callable, size: Vector2 = Vector2(340, 62), col: Color = Color(0.16, 0.2, 0.45)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 26)
	_style(b, col)
	b.pressed.connect(func():
		Game.sfx("ui")
		cb.call())
	parent.add_child(b)
	return b


func _center_box(sep: int = 14) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cur.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", sep)
	cc.add_child(vb)
	return vb


# ------------------------------------------------------------------ small handlers
func _go(flow: String) -> void:
	if flow != "browse":
		Game.mode = flow
	show_select(1, flow)


func _set_env(i: int, flow: String) -> void:
	Game.sfx("ui")
	Game.env = i
	Game.save_game()
	show_env(flow)


func _set_diff(i: int, flow: String) -> void:
	Game.difficulty = i
	Game.save_game()
	show_env(flow)


func _toggle_lang() -> void:
	Game.lang = "en" if Game.lang == "fa" else "fa"
	Game.save_game()
	show_settings()


func _cycle_gfx() -> void:
	Game.gfx = (Game.gfx + 1) % 3
	Game.save_game()
	show_settings()


func _reset_progress() -> void:
	Game.reset_progress()
	show_settings()


func _on_volume(val: float) -> void:
	Game.volume = val
	Game.apply_volume()
	Game.save_game()


# ------------------------------------------------------------------ main menu
func show_menu() -> void:
	_clear()
	cur = _screen()
	var vb := _center_box(10)
	var title := _lbl(vb, "LEGENDS OF FIGHT", 88, Color(1.0, 0.82, 0.2))
	_lbl(vb, Game.t("title") if Game.lang == "fa" else "", 44, Color(1, 1, 1))
	title.pivot_offset = Vector2(400, 50)
	var tw := title.create_tween().set_loops()
	tw.tween_property(title, "scale", Vector2(1.04, 1.04), 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
	var info := _lbl(vb, "%s: %d    %s: %d" % [Game.t("coins"), Game.coins, Game.t("wins_label"), Game.wins], 22, Color(0.8, 0.9, 1))
	info.custom_minimum_size = Vector2(0, 34)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 10)
	vb.add_child(g)
	_btn(g, Game.t("start"), _go.bind("single"), Vector2(400, 62), Color(0.7, 0.18, 0.18))
	_btn(g, Game.t("two_player"), _go.bind("local"), Vector2(400, 62), Color(0.18, 0.4, 0.7))
	_btn(g, Game.t("tournament") + " (%d/10)" % mini(Game.stage + 1, 10), _go.bind("tournament"), Vector2(400, 62), Color(0.55, 0.35, 0.1))
	_btn(g, Game.t("practice"), _go.bind("practice"), Vector2(400, 62), Color(0.2, 0.5, 0.3))
	_btn(g, Game.t("fighters"), _go.bind("browse"), Vector2(400, 62))
	_btn(g, Game.t("envs"), show_env.bind("browse"), Vector2(400, 62))
	_btn(g, Game.t("settings"), show_settings, Vector2(400, 62))
	_btn(g, Game.t("help"), show_help, Vector2(400, 62))


# ------------------------------------------------------------------ fighter select
func show_select(pid: int, flow: String) -> void:
	_clear()
	cur = _screen()
	pick_pid = pid
	pick_flow = flow
	sel = Game.p1 if pid == 1 else Game.p2
	if sel >= Game.f_unlocked():
		sel = 0
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	cur.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	var head: String = Game.t("select_fighter")
	if flow == "local":
		head = Game.t("select_p1") if pid == 1 else Game.t("select_p2")
	elif flow == "tournament":
		head = Game.t("stage") + " " + str(mini(Game.stage + 1, 10)) + "/10 — " + Game.t("select_fighter")
	_lbl(v, head, 38, Color(1, 0.85, 0.3))
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	h.add_child(grid)
	cards.clear()
	for i in Game.FIGHTERS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 74)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_pick_card.bind(i))
		grid.add_child(b)
		cards.append(b)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	_make_preview(right)
	lbl_name = _lbl(right, "", 34, Color(1, 0.85, 0.3))
	lbl_style = _lbl(right, "", 22, Color(0.8, 0.9, 1))
	stat_bars.clear()
	for k in ["power", "speed", "defense"]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		right.add_child(row)
		var l := Label.new()
		l.text = Game.t(k)
		l.custom_minimum_size = Vector2(110, 0)
		row.add_child(l)
		var pb := ProgressBar.new()
		pb.max_value = 10
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(280, 20)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pb)
		stat_bars.append(pb)
	lbl_lock = _lbl(right, "", 20, Color(1, 0.4, 0.4))
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	v.add_child(foot)
	_btn(foot, Game.t("back"), show_menu, Vector2(200, 58))
	confirm_btn = _btn(foot, Game.t("confirm"), _confirm_pick, Vector2(260, 58), Color(0.15, 0.55, 0.25))
	_refresh_select()


func _make_preview(parent: Control) -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(340, 330)
	parent.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	svc.add_child(sv)
	var we := WorldEnvironment.new()
	var en := Environment.new()
	en.background_mode = Environment.BG_CLEAR_COLOR
	en.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	en.ambient_light_color = Color(0.65, 0.65, 0.75)
	en.ambient_light_energy = 1.0
	we.environment = en
	sv.add_child(we)
	var c := Camera3D.new()
	c.fov = 38.0
	sv.add_child(c)
	c.look_at_from_position(Vector3(0, 1.25, 4.2), Vector3(0, 0.95, 0))
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-35, -25, 0)
	sv.add_child(l)
	preview_fighter = Fighter.new()
	preview_fighter.preview = true
	sv.add_child(preview_fighter)
	preview_fighter.setup(Game.FIGHTERS[sel], 1)
	var tw := preview_fighter.create_tween().set_loops()
	tw.tween_property(preview_fighter, "rotation:y", 0.6, 2.0).from(-0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(preview_fighter, "rotation:y", -0.6, 2.0).set_trans(Tween.TRANS_SINE)


func _pick_card(i: int) -> void:
	Game.sfx("ui")
	sel = i
	_refresh_select()


func _refresh_select() -> void:
	for i in cards.size():
		var b: Button = cards[i]
		var locked: bool = i >= Game.f_unlocked()
		b.text = ("🔒 " if locked else "") + Game.nm(i)
		var col: Color = Color(0.25, 0.25, 0.28) if locked else Color(Game.FIGHTERS[i].col).darkened(0.35)
		_style(b, col, i == sel)
	var f: Dictionary = Game.FIGHTERS[sel]
	lbl_name.text = Game.nm(sel)
	lbl_style.text = Game.style_name(sel)
	stat_bars[0].value = f.pow
	stat_bars[1].value = f.spd
	stat_bars[2].value = f.def
	var locked_sel: bool = sel >= Game.f_unlocked()
	lbl_lock.text = (Game.t("win_more") % ((sel - 5) * 2 - Game.wins)) if locked_sel else ""
	confirm_btn.disabled = locked_sel
	if preview_fighter:
		preview_fighter.setup(f, 1)


func _confirm_pick() -> void:
	if pick_pid == 1:
		Game.p1 = sel
	else:
		Game.p2 = sel
	Game.save_game()
	match pick_flow:
		"browse":
			show_menu()
		"local":
			if pick_pid == 1:
				show_select(2, "local")
			else:
				show_env("local")
		"tournament":
			start_fight()
		_:
			show_env(pick_flow)


# ------------------------------------------------------------------ arena select
func show_env(flow: String) -> void:
	_clear()
	cur = _screen()
	var vb := _center_box(12)
	_lbl(vb, Game.t("select_env"), 38, Color(1, 0.85, 0.3))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	vb.add_child(g)
	for i in Game.ENVS.size():
		var locked: bool = i >= Game.e_unlocked()
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 90)
		b.add_theme_font_size_override("font_size", 22)
		b.text = ("🔒 " if locked else "") + Game.env_name(i)
		var col: Color = Color(0.25, 0.25, 0.28) if locked else Color(Game.ENVS[i].top).lerp(Color(Game.ENVS[i].hor), 0.4).darkened(0.1)
		_style(b, col, i == Game.env)
		b.disabled = locked
		b.pressed.connect(_set_env.bind(i, flow))
		g.add_child(b)
	if flow == "single":
		_lbl(vb, Game.t("difficulty"), 26, Color(0.8, 0.9, 1))
		var dr := HBoxContainer.new()
		dr.alignment = BoxContainer.ALIGNMENT_CENTER
		dr.add_theme_constant_override("separation", 12)
		vb.add_child(dr)
		var names: Array = ["easy", "medium", "hard"]
		for i in 3:
			var db := _btn(dr, Game.t(names[i]), _set_diff.bind(i, flow), Vector2(180, 54))
			_style(db, Color(0.16, 0.2, 0.45), i == Game.difficulty)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	vb.add_child(foot)
	_btn(foot, Game.t("back"), show_menu, Vector2(200, 58))
	if flow != "browse":
		_btn(foot, Game.t("start_fight"), start_fight, Vector2(280, 58), Color(0.7, 0.18, 0.18))


# ------------------------------------------------------------------ settings / help
func show_settings() -> void:
	_clear()
	cur = _screen()
	var vb := _center_box(14)
	_lbl(vb, Game.t("settings"), 44, Color(1, 0.85, 0.3))
	_btn(vb, Game.t("language"), _toggle_lang, Vector2(460, 60))
	var gnames: Array = [Game.t("low"), Game.t("med"), Game.t("high")]
	_btn(vb, Game.t("graphics") % gnames[Game.gfx], _cycle_gfx, Vector2(460, 60))
	_lbl(vb, Game.t("volume"), 24)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = Game.volume
	sl.custom_minimum_size = Vector2(460, 30)
	sl.value_changed.connect(_on_volume)
	vb.add_child(sl)
	_btn(vb, Game.t("reset"), _reset_progress, Vector2(460, 60), Color(0.5, 0.15, 0.15))
	_btn(vb, Game.t("back"), show_menu, Vector2(460, 60))


func show_help() -> void:
	_clear()
	cur = _screen()
	var vb := _center_box(14)
	_lbl(vb, Game.t("help"), 44, Color(1, 0.85, 0.3))
	var l := Label.new()
	l.text = Game.t("help_text")
	l.custom_minimum_size = Vector2(1000, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 24)
	vb.add_child(l)
	_btn(vb, Game.t("back"), show_menu, Vector2(300, 60))


# ------------------------------------------------------------------ match flow
func start_fight() -> void:
	_clear()
	ui.visible = false
	match Game.mode:
		"tournament":
			Game.p2 = (Game.p1 + 1 + Game.stage) % 12
			Game.env = Game.stage % 8
		"single":
			Game.p2 = (Game.p1 + 1 + randi() % 11) % 12
		"practice":
			Game.p2 = (Game.p1 + 1) % 12
	fight = Fight.new()
	if Game.mode == "tournament":
		fight.stage_text = Game.t("stage") + " " + str(Game.stage + 1) + "/10 · "
	add_child(fight)
	fight.finished.connect(_on_fight_done)
	fight.quit_requested.connect(_on_quit)


func _end_fight() -> void:
	if fight:
		fight.queue_free()
		fight = null
	ui.visible = true
	Game.play_music(8)


func _on_quit() -> void:
	_end_fight()
	show_menu()


func _on_fight_done(p1_won: bool) -> void:
	_end_fight()
	var notes: Array = []
	last_gain = 0
	var champion: bool = false
	if p1_won and Game.mode != "local" and Game.mode != "practice":
		var bf: int = Game.f_unlocked()
		var be: int = Game.e_unlocked()
		Game.wins += 1
		if Game.mode == "tournament":
			last_gain = 50 + Game.stage * 10
			Game.stage += 1
			if Game.stage >= 10:
				champion = true
				Game.stage = 0
				last_gain += 300
		else:
			last_gain = 30 + Game.difficulty * 20
		Game.coins += last_gain
		if Game.f_unlocked() > bf or Game.e_unlocked() > be:
			notes.append(Game.t("new_unlock"))
		Game.save_game()
	show_result(p1_won, notes, champion)


func show_result(p1_won: bool, notes: Array, champion: bool) -> void:
	_clear()
	cur = _screen()
	var vb := _center_box(16)
	var txt: String = Game.t("you_win") if p1_won else Game.t("you_lose")
	if Game.mode == "local":
		txt = Game.t("p1_wins") if p1_won else Game.t("p2_wins")
	_lbl(vb, txt, 72, Color(1, 0.85, 0.3) if p1_won else Color(1, 0.4, 0.4))
	if champion:
		_lbl(vb, Game.t("champion"), 40, Color(0.5, 1, 0.6))
	if last_gain > 0:
		_lbl(vb, Game.t("reward") % last_gain, 30)
	for n in notes:
		_lbl(vb, n, 30, Color(0.5, 1, 0.6))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	var again: String = Game.t("rematch")
	if Game.mode == "tournament":
		again = Game.t("next_stage") if p1_won else Game.t("retry")
	_btn(row, again, start_fight, Vector2(300, 62), Color(0.7, 0.18, 0.18))
	_btn(row, Game.t("menu"), show_menu, Vector2(240, 62))
