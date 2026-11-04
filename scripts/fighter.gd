class_name Fighter
extends Node3D
## One fighter: procedural 3D model, state machine, hitboxes and damage.

signal died

const RobotData := preload("res://scripts/robot_data.gd")

const ATTACKS := {
	"p1": {"limb": "arm_r", "su": 0.06, "ac": 0.09, "rc": 0.12, "dmg": 4.0, "rng": 1.2, "kb": 1.2, "stun": 0.22, "snd": "punch"},
	"p2": {"limb": "arm_l", "su": 0.06, "ac": 0.09, "rc": 0.12, "dmg": 5.0, "rng": 1.2, "kb": 1.4, "stun": 0.22, "snd": "punch"},
	"p3": {"limb": "arm_r", "su": 0.14, "ac": 0.12, "rc": 0.26, "dmg": 11.0, "rng": 1.4, "kb": 4.5, "stun": 0.4, "snd": "whoosh"},
	"k1": {"limb": "leg_r", "su": 0.09, "ac": 0.11, "rc": 0.18, "dmg": 6.0, "rng": 1.5, "kb": 1.8, "stun": 0.25, "snd": "kick"},
	"k2": {"limb": "leg_l", "su": 0.09, "ac": 0.11, "rc": 0.18, "dmg": 7.0, "rng": 1.5, "kb": 2.0, "stun": 0.25, "snd": "kick"},
	"k3": {"limb": "leg_r", "su": 0.2, "ac": 0.14, "rc": 0.32, "dmg": 13.0, "rng": 1.75, "kb": 5.5, "stun": 0.45, "snd": "whoosh"},
	"sp": {"limb": "both", "su": 0.22, "ac": 0.18, "rc": 0.36, "dmg": 20.0, "rng": 2.4, "kb": 7.0, "stun": 0.6, "snd": "special"},
	"ult": {"limb": "both", "su": 0.4, "ac": 0.3, "rc": 0.55, "dmg": 38.0, "rng": 3.2, "kb": 10.0, "stun": 0.9, "snd": "special"},
}

var d: Dictionary = {}
var pid: int = 1
var facing: int = 1
var preview: bool = false
var hp: float = 100.0
var max_hp: float = 100.0
var energy: float = 0.0
var state: String = "idle"   # idle, walk, block, dodge, attack, hit, ko
var t: float = 0.0
var vy: float = 0.0
var kvx: float = 0.0
var inv: float = 0.0
var stun: float = 0.0
var inp: Dictionary = {"left": false, "right": false, "block": false}
var queue: Array = []
var prev_block: bool = false
var opp: Fighter = null
var atk: Dictionary = {}
var atk_hit: bool = false
var fx_done: bool = false
var chain: int = 0
var chain_t: float = 0.0
var buffered: String = ""
var buf_t: float = 0.0
var bounds: float = 6.5
var frozen: bool = true
var body: Node3D
var upper: Node3D
var parts: Dictionary = {}
var spd: float = 1.0
var dmgm: float = 1.0
var defm: float = 1.0
var ph: float = 0.0
var upper_y: float = 0.85
var arm_rest: float = 0.0
var arm_zm: float = 1.0


# ------------------------------------------------------------------ building
func _mi(parent: Node3D, mesh: Mesh, col: Color, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.75
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _box(v: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = v
	return b


func setup(data: Dictionary, player: int, sc: float = 1.0) -> void:
	for c in get_children():
		c.queue_free()
	parts.clear()
	d = data
	pid = player
	spd = 0.8 + float(d.spd) * 0.045
	dmgm = 0.8 + float(d.pow) * 0.04
	defm = 0.8 + float(d.def) * 0.04
	scale = Vector3.ONE * sc
	upper_y = 0.85
	arm_rest = 0.0
	arm_zm = 1.0
	if d.has("model"):
		_build_robot()
		return
	var suit: Color = d.col
	var skin: Color = d.skin
	var hair: Color = d.hair
	if pid == 2 and Game.p1 == Game.p2:
		suit = suit.inverted()
	var pants: Color = suit.darkened(0.5)
	body = Node3D.new()
	add_child(body)
	upper = Node3D.new()
	upper.position = Vector3(0, 0.85, 0)
	body.add_child(upper)
	_mi(upper, _cap(0.27, 0.8), suit, Vector3(0, 0.2, 0))
	_mi(upper, _box(Vector3(0.56, 0.1, 0.4)), Color(0.08, 0.08, 0.08), Vector3(0, -0.12, 0))
	_mi(upper, _sph(0.2), skin, Vector3(0, 0.82, 0))
	_mi(upper, _box(Vector3(0.4, 0.12, 0.4)), hair, Vector3(0, 0.98, 0))
	_mi(upper, _box(Vector3(0.06, 0.04, 0.02)), Color.BLACK, Vector3(-0.07, 0.84, -0.19))
	_mi(upper, _box(Vector3(0.06, 0.04, 0.02)), Color.BLACK, Vector3(0.07, 0.84, -0.19))
	for side in ["arm_r", "arm_l"]:
		var pv := Node3D.new()
		pv.position = Vector3(0.36 if side == "arm_r" else -0.36, 0.5, 0)
		upper.add_child(pv)
		_mi(pv, _cap(0.085, 0.62), suit, Vector3(0, -0.28, 0))
		_mi(pv, _sph(0.105), skin, Vector3(0, -0.6, 0))
		parts[side] = pv
	for side in ["leg_r", "leg_l"]:
		var pv := Node3D.new()
		pv.position = Vector3(0.13 if side == "leg_r" else -0.13, 0.82, 0)
		body.add_child(pv)
		_mi(pv, _cap(0.11, 0.85), pants, Vector3(0, -0.4, 0))
		_mi(pv, _box(Vector3(0.16, 0.1, 0.3)), Color(0.1, 0.1, 0.1), Vector3(0, -0.82, -0.08))
		parts[side] = pv
	body.rotation.y = PI if preview else -PI / 2.0 * float(facing)


# ------------------------------------------------------------------ imported 3D robot (Reza)
func _robot_mat(n: String, tint: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var c: Color = Color(0.553, 0.0, 0.005)
	m.metallic = 0.3
	m.roughness = 0.45
	match n:
		"BODY2":
			m.metallic = 0.35
			m.roughness = 0.4
		"JACKET.002":
			c = Color(0.10, 0.36, 0.41)
			m.metallic = 0.0
			m.roughness = 0.6
		"LOGO":
			c = Color(0.62, 0.02, 0.02)
		"LOGO.002":
			c = Color(0.41, 0.0, 0.003)
		"METAL":
			m.metallic = 0.6
			m.roughness = 0.3
		"GLOW":
			c = Color(0.0, 0.72, 1.0)
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = 3.0
	if tint and n != "GLOW":
		c = Color(c.b, c.g, c.r)
	m.albedo_color = c
	return m


func _build_robot() -> void:
	var tint: bool = pid == 2 and Game.p1 == Game.p2
	body = Node3D.new()
	add_child(body)
	upper = Node3D.new()
	upper.position = Vector3(0, RobotData.HIP_Y, 0)
	body.add_child(upper)
	upper_y = RobotData.HIP_Y
	arm_rest = 0.5
	arm_zm = 0.0
	for side in ["arm_r", "arm_l"]:
		var pv := Node3D.new()
		pv.position = RobotData.PIVOTS[side]
		upper.add_child(pv)
		parts[side] = pv
	for side in ["leg_r", "leg_l"]:
		var pv := Node3D.new()
		pv.position = RobotData.PIVOTS[side]
		body.add_child(pv)
		parts[side] = pv
	var mats: Dictionary = {}
	for p in RobotData.PARTS:
		var mesh: Mesh = load(String(p[2])) as Mesh
		if mesh == null:
			continue
		if not mats.has(p[1]):
			mats[p[1]] = _robot_mat(String(p[1]), tint)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mats[p[1]]
		var parent: Node3D = upper if p[0] == "torso" else parts[p[0]]
		parent.add_child(mi)
	body.rotation.y = PI if preview else -PI / 2.0 * float(facing)


func reset_for_round(x: float, face: int) -> void:
	position = Vector3(x, 0, 0)
	facing = face
	hp = max_hp
	energy = 0.0
	state = "idle"
	t = 0.0
	vy = 0.0
	kvx = 0.0
	inv = 0.0
	atk = {}
	chain = 0
	buffered = ""
	inp = {"left": false, "right": false, "block": false}
	queue.clear()
	if body:
		body.rotation.x = 0.0
		body.position.y = 0.0


func press(k: String) -> void:
	queue.append(k)


# ------------------------------------------------------------------ pose
func _process(delta: float) -> void:
	if body == null:
		return
	ph += delta
	var ty: float = PI if preview else -PI / 2.0 * float(facing)
	body.rotation.y = lerp_angle(body.rotation.y, ty, minf(1.0, delta * 16.0))
	var ar: float = 0.8
	var al: float = 0.8
	var lr: float = 0.0
	var ll: float = 0.0
	var lean: float = 0.0
	var crouch: float = 0.0
	var bob: float = sin(ph * 3.0) * 0.015
	var air: bool = position.y > 0.05
	match state:
		"walk":
			var s: float = sin(ph * 11.0)
			lr = s * 0.7
			ll = -s * 0.7
		"block":
			ar = 1.75
			al = 1.75
			crouch = 0.12
			lean = -0.12
		"dodge":
			lean = 0.45
			lr = 0.5
			ll = -0.3
		"hit":
			lean = 0.55
			ar = 0.2
			al = 0.3
		"attack":
			if not atk.is_empty():
				var su: float = float(atk.su)
				var ac: float = float(atk.ac)
				var rc: float = float(atk.rc)
				var ext: float = 0.0
				if t < su:
					ext = -0.25 * (t / su)
				elif t < su + ac:
					ext = lerpf(-0.25, 1.0, (t - su) / ac)
				else:
					ext = lerpf(1.0, 0.0, clampf((t - su - ac) / rc, 0.0, 1.0))
				var limb: String = atk.limb
				if limb == "arm_r":
					ar = 0.8 + ext * 0.85
					lean = -0.25 * ext
				elif limb == "arm_l":
					al = 0.8 + ext * 0.85
					lean = -0.25 * ext
				elif limb == "leg_r":
					lr = ext * 1.5
					lean = 0.18 * ext
				elif limb == "leg_l":
					ll = ext * 1.5
					lean = 0.18 * ext
				else:
					ar = 0.8 + ext * 0.9
					al = ar
					lean = -0.25 * ext
		_:
			ar = 0.8 + sin(ph * 3.0) * 0.05
			al = 0.8 - sin(ph * 3.0) * 0.05
	if air and state != "attack" and state != "hit":
		lr = 0.9
		ll = 0.9
		ar = 1.2
		al = 1.2
	parts["arm_r"].rotation = Vector3(ar - arm_rest, 0.0, -0.25 * arm_zm)
	parts["arm_l"].rotation = Vector3(al - arm_rest, 0.0, 0.25 * arm_zm)
	parts["leg_r"].rotation.x = lr
	parts["leg_l"].rotation.x = ll
	upper.rotation.x = lerpf(upper.rotation.x, lean, minf(1.0, delta * 20.0))
	upper.position.y = upper_y - crouch + bob
	var ko: bool = state == "ko"
	body.rotation.x = lerpf(body.rotation.x, 1.45 if ko else 0.0, minf(1.0, delta * 5.0))
	body.position.y = lerpf(body.position.y, 0.25 if ko else 0.0, minf(1.0, delta * 5.0))


# ------------------------------------------------------------------ logic
func _physics_process(delta: float) -> void:
	if opp == null:
		return
	if frozen:
		queue.clear()
		return
	t += delta
	inv = maxf(inv - delta, 0.0)
	if chain_t > 0.0:
		chain_t -= delta
		if chain_t <= 0.0:
			chain = 0
	if buf_t > 0.0:
		buf_t -= delta
		if buf_t <= 0.0:
			buffered = ""
	if position.y > 0.0 or vy > 0.0:
		vy -= 24.0 * delta
		position.y += vy * delta
		if position.y <= 0.0:
			position.y = 0.0
			vy = 0.0
	if absf(kvx) > 0.05:
		position.x += kvx * delta
		kvx = move_toward(kvx, 0.0, 16.0 * delta)
	var dx: float = opp.position.x - position.x
	if (state == "idle" or state == "walk" or state == "block") and absf(dx) > 0.05:
		facing = 1 if dx > 0.0 else -1
	var on_ground: bool = position.y <= 0.001
	match state:
		"ko":
			pass
		"hit":
			if t >= stun:
				state = "idle"
		"dodge":
			position.x -= float(facing) * 5.5 * delta
			if t >= 0.26:
				state = "idle"
		"attack":
			_attack_step(delta)
		_:
			_free_step(delta, on_ground)
	# separation and arena bounds
	var dx2: float = opp.position.x - position.x
	if state != "ko" and absf(dx2) < 0.8 and position.y < 0.9 and opp.position.y < 0.9:
		var dir: float = signf(dx2)
		if dir == 0.0:
			dir = -float(facing)
		position.x -= dir * (0.8 - absf(dx2)) * 0.5
	position.x = clampf(position.x, -bounds, bounds)
	prev_block = inp.block
	queue.clear()


func _free_step(delta: float, on_ground: bool) -> void:
	var mv: int = (1 if inp.right else 0) - (1 if inp.left else 0)
	if inp.block and on_ground:
		if not prev_block and mv != 0 and mv == -facing:
			state = "dodge"
			t = 0.0
			inv = 0.28
			Game.sfx("whoosh")
			return
		state = "block"
	elif state == "block":
		state = "idle"
	for k in queue:
		if state == "block" and k != "jump":
			continue
		if k in ["punch", "kick", "special", "jump"]:
			_do(k)
			if state == "attack":
				return
	if state == "block":
		return
	if mv != 0:
		var m: float = 3.4 * spd * (0.7 if mv == -facing else 1.0)
		position.x += float(mv) * m * delta
		if on_ground:
			state = "walk"
	elif state == "walk":
		state = "idle"


func _do(k: String) -> void:
	match k:
		"jump":
			if position.y <= 0.001:
				vy = 9.5
		"punch":
			_start("p")
		"kick":
			_start("k")
		"special":
			_start("sp")


func _start(kind: String) -> void:
	var key: String = ""
	if kind == "sp":
		if energy >= 100.0:
			key = "ult"
			energy = 0.0
		elif energy >= 50.0:
			key = "sp"
			energy -= 50.0
		else:
			return
	else:
		key = kind + str(chain + 1)
		chain = (chain + 1) % 3
	atk = ATTACKS[key]
	atk_hit = false
	fx_done = false
	state = "attack"
	t = 0.0
	Game.sfx(String(atk.get("snd", "whoosh")))


func _attack_step(delta: float) -> void:
	for k in queue:
		if k in ["punch", "kick", "special"]:
			buffered = k
			buf_t = 0.35
	var su: float = float(atk.su)
	var ac: float = float(atk.ac)
	var rc: float = float(atk.rc)
	if t < su:
		position.x += float(facing) * 1.2 * delta
	if t >= su and t < su + ac:
		if String(atk.limb) == "both" and not fx_done:
			fx_done = true
			var c: Color = Color(d.col).lightened(0.4)
			_spark(position + Vector3(float(facing) * 1.4, 1.2, 0.0), c, 0.55)
		if not atk_hit:
			_try_hit()
	if t >= su + ac + rc:
		state = "idle"
		chain_t = 0.55
		atk = {}
		if buffered != "":
			var b: String = buffered
			buffered = ""
			_do(b)


func _try_hit() -> void:
	var dx: float = opp.position.x - position.x
	var rng: float = float(atk.rng) * float(d.rch)
	var in_front: bool = (dx > 0.0 and facing == 1) or (dx < 0.0 and facing == -1) or absf(dx) < 0.35
	if in_front and absf(dx) <= rng and absf(opp.position.y - position.y) < 1.1:
		atk_hit = true
		opp.take_hit(atk, self)


func take_hit(a: Dictionary, from: Fighter) -> void:
	if state == "ko" or inv > 0.0:
		return
	var dmg: float = float(a.dmg) * from.dmgm / defm
	var dirx: float = signf(position.x - from.position.x)
	if dirx == 0.0:
		dirx = -float(facing)
	var pos: Vector3 = position + Vector3(0, 1.2, 0)
	if state == "block" and signf(from.position.x - position.x) == float(facing):
		hp -= dmg * 0.1
		kvx = dirx * float(a.kb) * 0.3
		energy = minf(100.0, energy + 3.0)
		from.energy = minf(100.0, from.energy + 2.0)
		Game.sfx("block")
		_spark(pos, Color(0.4, 0.9, 1.0), 0.25)
	else:
		hp -= dmg
		state = "hit"
		t = 0.0
		stun = float(a.stun)
		kvx = dirx * float(a.kb)
		atk = {}
		chain = 0
		buffered = ""
		energy = minf(100.0, energy + dmg * 0.35)
		from.energy = minf(100.0, from.energy + dmg * 0.7)
		Game.sfx("hit")
		_spark(pos, Color(1.0, 0.7, 0.2), 0.18 + dmg * 0.01)
	if hp <= 0.0:
		hp = 0.0
		state = "ko"
		t = 0.0
		Game.sfx("ko")
		died.emit()


func _spark(pos: Vector3, c: Color, size: float) -> void:
	var par := get_parent()
	if par == null:
		return
	var m := MeshInstance3D.new()
	m.mesh = _sph(size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	par.add_child(m)
	m.global_position = pos
	m.scale = Vector3.ONE * 0.5
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3.ONE * 2.2, 0.12)
	tw.tween_property(m, "scale", Vector3.ZERO, 0.08)
	tw.tween_callback(m.queue_free)
