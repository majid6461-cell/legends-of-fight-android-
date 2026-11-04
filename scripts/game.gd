extends Node
## Global state, data tables, localisation, save/load and procedural audio.

var lang: String = "fa"
var gfx: int = 1
var volume: float = 0.8
var mode: String = "single"   # single, local, tournament, practice
var difficulty: int = 1       # 0 easy, 1 medium, 2 hard
var p1: int = 0
var p2: int = 1
var env: int = 0
var stage: int = 0
var wins: int = 0
var coins: int = 0
var ui_theme: Theme = null

const SAVE_PATH := "user://legends_save.cfg"

const FIGHTERS: Array = [
	{"fa": "رضا «پتک»", "en": "Reza 'Hammer'", "sfa": "مبارز خیابانی", "sen": "Street Brawler", "pow": 8, "spd": 5, "def": 6, "rch": 1.0, "col": Color("c0392b"), "skin": Color("e0ac69"), "hair": Color("1a1a1a")},
	{"fa": "استاد چن", "en": "Master Chen", "sfa": "استاد کونگ‌فو", "sen": "Kung-Fu Master", "pow": 6, "spd": 8, "def": 6, "rch": 1.0, "col": Color("f1c40f"), "skin": Color("f0c8a0"), "hair": Color("111111")},
	{"fa": "کنجی", "en": "Kenji", "sfa": "کاراته‌کار", "sen": "Karateka", "pow": 7, "spd": 7, "def": 6, "rch": 1.0, "col": Color("ecf0f1"), "skin": Color("e8b88a"), "hair": Color("222222")},
	{"fa": "مارکوس «مشت‌آهنین»", "en": "Marcus 'Iron Fist'", "sfa": "بوکسور", "sen": "Boxer", "pow": 9, "spd": 6, "def": 5, "rch": 0.9, "col": Color("2980b9"), "skin": Color("8d5524"), "hair": Color("0a0a0a")},
	{"fa": "کاگه", "en": "Kage", "sfa": "نینجا", "sen": "Ninja", "pow": 5, "spd": 10, "def": 4, "rch": 1.0, "col": Color("2c3e50"), "skin": Color("e0ac69"), "hair": Color("2c3e50")},
	{"fa": "جیک «قفس»", "en": "Jake 'Cage'", "sfa": "مبارز MMA", "sen": "MMA Fighter", "pow": 8, "spd": 6, "def": 7, "rch": 1.0, "col": Color("27ae60"), "skin": Color("c68642"), "hair": Color("5a3a1a")},
	{"fa": "سایه", "en": "Shadow", "sfa": "رزمی‌کار مرموز", "sen": "Mystery Fighter", "pow": 7, "spd": 8, "def": 6, "rch": 1.0, "col": Color("6c3483"), "skin": Color("b0b0c0"), "hair": Color("d0d0ff")},
	{"fa": "استاد پارک", "en": "Master Park", "sfa": "استاد تکواندو", "sen": "Taekwondo Master", "pow": 6, "spd": 8, "def": 5, "rch": 1.15, "col": Color("e8e8e8"), "skin": Color("e8c39e"), "hair": Color("111111")},
	{"fa": "تایتان", "en": "Titan", "sfa": "مبارز قدرتمند", "sen": "Powerhouse", "pow": 10, "spd": 3, "def": 9, "rch": 1.0, "col": Color("7f8c8d"), "skin": Color("d9a066"), "hair": Color("3b2a1a")},
	{"fa": "ساکورا", "en": "Sakura", "sfa": "کاراته‌کار", "sen": "Karateka", "pow": 6, "spd": 9, "def": 5, "rch": 1.0, "col": Color("e84393"), "skin": Color("f3d0b0"), "hair": Color("3d1f3d")},
	{"fa": "بهرام پهلوان", "en": "Bahram the Champion", "sfa": "پهلوان قدرتمند", "sen": "Powerhouse", "pow": 9, "spd": 4, "def": 9, "rch": 1.0, "col": Color("16a085"), "skin": Color("c68642"), "hair": Color("1a1a1a")},
	{"fa": "یوکی", "en": "Yuki", "sfa": "نینجا", "sen": "Ninja", "pow": 5, "spd": 10, "def": 5, "rch": 1.05, "col": Color("5dade2"), "skin": Color("f5d5b8"), "hair": Color("f0f0f0")},
]

const ENVS: Array = [
	{"fa": "خیابان نئونی شب", "en": "Neon Night Street", "top": Color("0b0a2a"), "hor": Color("4a2a6a"), "ground": Color("1b1b26"), "light": Color("b9a8ff"), "amb": Color("50406e"), "fx": "rain", "prop": "street"},
	{"fa": "معبد شرقی", "en": "Eastern Temple", "top": Color("e07b39"), "hor": Color("f6d6a0"), "ground": Color("6b4a2f"), "light": Color("ffd9a0"), "amb": Color("8a6a50"), "fx": "leaf", "prop": "temple"},
	{"fa": "سالن مسابقات", "en": "Pro Arena", "top": Color("141414"), "hor": Color("2a2a3a"), "ground": Color("2f3e6b"), "light": Color("ffffff"), "amb": Color("707080"), "fx": "none", "prop": "arena"},
	{"fa": "پشت‌بام آسمان‌خراش", "en": "Skyscraper Rooftop", "top": Color("1f3a6b"), "hor": Color("ff9a5a"), "ground": Color("40444c"), "light": Color("ffc08a"), "amb": Color("70607a"), "fx": "none", "prop": "rooftop"},
	{"fa": "جنگل استوایی", "en": "Tropical Jungle", "top": Color("5ec2d8"), "hor": Color("c8f0b0"), "ground": Color("2d5a2d"), "light": Color("fff2c0"), "amb": Color("7a9a70"), "fx": "firefly", "prop": "jungle"},
	{"fa": "کارخانه صنعتی", "en": "Industrial Factory", "top": Color("2a2018"), "hor": Color("6a4a30"), "ground": Color("3a3a3a"), "light": Color("ffb070"), "amb": Color("605048"), "fx": "ember", "prop": "factory"},
	{"fa": "قلعه باستانی", "en": "Ancient Castle", "top": Color("2a3550"), "hor": Color("8a8aa0"), "ground": Color("5a5a5a"), "light": Color("c8d0ff"), "amb": Color("606878"), "fx": "none", "prop": "castle"},
	{"fa": "میدان برفی", "en": "Snow Arena", "top": Color("9ec4e8"), "hor": Color("eef6ff"), "ground": Color("e8f0f8"), "light": Color("ffffff"), "amb": Color("9aa8b8"), "fx": "snow", "prop": "snow"},
]

const T := {
	"title": ["افسانه‌های مبارزه", "LEGENDS OF FIGHT"],
	"start": ["شروع بازی (تک‌نفره)", "Start (Single Player)"],
	"two_player": ["دو نفره", "Two Players"],
	"tournament": ["تورنمنت", "Tournament"],
	"practice": ["تمرین", "Practice"],
	"fighters": ["انتخاب مبارز", "Choose Fighter"],
	"envs": ["انتخاب محیط", "Choose Arena"],
	"settings": ["تنظیمات", "Settings"],
	"help": ["راهنمای بازی", "How to Play"],
	"back": ["بازگشت", "Back"],
	"confirm": ["تأیید", "Confirm"],
	"select_p1": ["بازیکن اول: مبارز را انتخاب کن", "Player 1: choose your fighter"],
	"select_p2": ["بازیکن دوم: مبارز را انتخاب کن", "Player 2: choose your fighter"],
	"select_fighter": ["مبارز خود را انتخاب کن", "Choose your fighter"],
	"select_env": ["محیط مبارزه را انتخاب کن", "Choose the arena"],
	"power": ["قدرت", "Power"],
	"speed": ["سرعت", "Speed"],
	"defense": ["دفاع", "Defense"],
	"locked": ["قفل است", "Locked"],
	"win_more": ["برای بازشدن %d پیروزی دیگر لازم است", "Win %d more matches to unlock"],
	"difficulty": ["سطح دشواری", "Difficulty"],
	"easy": ["آسان", "Easy"],
	"medium": ["متوسط", "Medium"],
	"hard": ["سخت", "Hard"],
	"start_fight": ["شروع مبارزه", "Fight!"],
	"language": ["زبان: فارسی", "Language: English"],
	"graphics": ["کیفیت گرافیک: %s", "Graphics: %s"],
	"low": ["کم", "Low"],
	"med": ["متوسط", "Medium"],
	"high": ["زیاد", "High"],
	"volume": ["صدا", "Volume"],
	"reset": ["پاک کردن پیشرفت", "Reset progress"],
	"round": ["راند", "Round"],
	"fight": ["مبارزه!", "FIGHT!"],
	"ko": ["ناک‌اوت!", "K.O.!"],
	"time_up": ["پایان زمان", "TIME UP"],
	"draw": ["مساوی", "DRAW"],
	"you_win": ["پیروز شدی!", "YOU WIN!"],
	"you_lose": ["شکست خوردی", "YOU LOSE"],
	"p1_wins": ["بازیکن اول برنده شد!", "Player 1 wins!"],
	"p2_wins": ["بازیکن دوم برنده شد!", "Player 2 wins!"],
	"next_stage": ["مرحله بعد", "Next stage"],
	"rematch": ["مبارزه دوباره", "Rematch"],
	"retry": ["تلاش دوباره", "Retry"],
	"menu": ["منو", "Menu"],
	"stage": ["مرحله", "Stage"],
	"champion": ["قهرمان تورنمنت شدی!", "You are the tournament champion!"],
	"coins": ["سکه", "Coins"],
	"reward": ["پاداش: %d سکه", "Reward: %d coins"],
	"new_unlock": ["محتوای جدید آزاد شد!", "New content unlocked!"],
	"wins_label": ["پیروزی‌ها", "Wins"],
	"help_text": [
		"کنترل‌ها:\n• دکمه‌های چپ صفحه: حرکت به چپ/راست و پرش\n• مشت و لگد: سه ضربه پیاپی = ضربه سنگین (کمبو)\n• دفاع: نگه دار تا ضربات را بگیری؛ هم‌زمان با دکمه عقب = جاخالی\n• ویژه: با ۵۰٪ انرژی ضربه ویژه، با ۱۰۰٪ حرکت نهایی (Ultimate)\n• انرژی با زدن و خوردن ضربه پر می‌شود\n• هر مبارزه ۳ راند است؛ برنده ۲ راند\n• با پیروزی، سکه می‌گیری و مبارزان و محیط‌های جدید آزاد می‌شوند\n• کیبورد (برای تست): A/D/W حرکت، F مشت، G لگد، H دفاع، T ویژه | بازیکن دوم: ← → ↑، J K L I",
		"Controls:\n• Left side: move left/right and jump\n• Punch / Kick: three presses in a row = heavy finisher (combo)\n• Block: hold to guard; press while holding back = dodge\n• Special: 50% energy = special move, 100% = Ultimate\n• Energy fills when you hit and when you get hit\n• Every match is best of 3 rounds\n• Win to earn coins and unlock new fighters and arenas\n• Keyboard (testing): A/D/W move, F punch, G kick, H block, T special | P2: arrows, J K L I"],
	"practice_help": ["حالت تمرین: روی هدف تمرین کن. دکمه منو برای خروج.", "Practice: hit the dummy freely. Use Menu to leave."],
	"k_left": ["◀", "◀"],
	"k_right": ["▶", "▶"],
	"k_jump": ["▲", "▲"],
	"k_punch": ["مشت", "Punch"],
	"k_kick": ["لگد", "Kick"],
	"k_block": ["دفاع", "Block"],
	"k_special": ["ویژه", "Special"],
}

var _sounds: Dictionary = {}
var _pool: Array = []
var _pi: int = 0
var _music_player: AudioStreamPlayer
var _music_idx: int = -1


func _ready() -> void:
	load_game()
	var fp := "res://assets/fonts/Vazirmatn.ttf"
	if ResourceLoader.exists(fp):
		var th := Theme.new()
		th.default_font = load(fp)
		ui_theme = th
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -9.0
	add_child(_music_player)
	_sounds = {
		"punch": _wav(180.0, 0.12, 0.6, 22.0),
		"kick": _wav(120.0, 0.16, 0.7, 18.0),
		"hit": _wav(90.0, 0.2, 0.5, 14.0),
		"block": _wav(420.0, 0.08, 0.3, 30.0),
		"special": _wav(300.0, 0.4, 0.2, 5.0),
		"ko": _wav(60.0, 0.7, 0.4, 4.0),
		"ui": _wav(660.0, 0.08, 0.0, 25.0),
		"whoosh": _wav(500.0, 0.1, 0.9, 30.0),
	}
	apply_volume()


func t(k: String) -> String:
	var a: Array = T.get(k, [k, k])
	return a[0] if lang == "fa" else a[1]


func nm(i: int) -> String:
	return FIGHTERS[i]["fa"] if lang == "fa" else FIGHTERS[i]["en"]


func style_name(i: int) -> String:
	return FIGHTERS[i]["sfa"] if lang == "fa" else FIGHTERS[i]["sen"]


func env_name(i: int) -> String:
	return ENVS[i]["fa"] if lang == "fa" else ENVS[i]["en"]


@warning_ignore("integer_division")
func f_unlocked() -> int:
	return mini(12, 6 + wins / 2)


@warning_ignore("integer_division")
func e_unlocked() -> int:
	return mini(8, 3 + wins / 2)


func place(c: Control, ax: float, ay: float, ox: float, oy: float, w: float, h: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox + w
	c.offset_top = oy
	c.offset_bottom = oy + h


# ---------------------------------------------------------------- save / load
func save_game() -> void:
	var c := ConfigFile.new()
	c.set_value("s", "lang", lang)
	c.set_value("s", "gfx", gfx)
	c.set_value("s", "volume", volume)
	c.set_value("s", "wins", wins)
	c.set_value("s", "coins", coins)
	c.set_value("s", "stage", stage)
	c.set_value("s", "difficulty", difficulty)
	c.set_value("s", "env", env)
	c.set_value("s", "p1", p1)
	c.save(SAVE_PATH)


func load_game() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK:
		return
	lang = c.get_value("s", "lang", "fa")
	gfx = c.get_value("s", "gfx", 1)
	volume = c.get_value("s", "volume", 0.8)
	wins = c.get_value("s", "wins", 0)
	coins = c.get_value("s", "coins", 0)
	stage = c.get_value("s", "stage", 0)
	difficulty = c.get_value("s", "difficulty", 1)
	env = c.get_value("s", "env", 0)
	p1 = c.get_value("s", "p1", 0)
	if p1 >= f_unlocked():
		p1 = 0
	if env >= e_unlocked():
		env = 0


func reset_progress() -> void:
	wins = 0
	coins = 0
	stage = 0
	p1 = 0
	env = 0
	save_game()


# ---------------------------------------------------------------- audio
func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))


func sfx(n: String) -> void:
	if not _sounds.has(n) or _pool.is_empty():
		return
	var p: AudioStreamPlayer = _pool[_pi % _pool.size()]
	_pi += 1
	p.stream = _sounds[n]
	p.play()


func _wav(freq: float, dur: float, noise: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / float(rate)
		var e := exp(-tt * decay)
		var s := (sin(TAU * freq * tt) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise) * e
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 28000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func play_music(idx: int) -> void:
	if idx == _music_idx and _music_player.playing:
		return
	_music_idx = idx
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + idx
	var pent: Array = [0, 3, 5, 7, 10, 12, 15]
	var base: float = 82.4 * pow(2.0, float((idx * 2) % 12) / 12.0)
	var step := 0.3
	var rate := 22050
	var notes := 8
	var n := int(rate * step * notes)
	var seq: Array = []
	for i in notes:
		seq.append(pent[rng.randi() % pent.size()])
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / float(rate)
		var k := int(tt / step) % notes
		var lt := fmod(tt, step)
		var e := exp(-lt * 5.0)
		var f_lead: float = base * 2.0 * pow(2.0, float(seq[k]) / 12.0)
		var f_bass: float = base * 0.5 * (1.0 if k % 4 < 2 else 1.5)
		var s := (signf(sin(TAU * f_lead * tt)) * 0.10 + sin(TAU * f_bass * tt) * 0.35) * e
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 24000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	_music_player.stream = w
	_music_player.play()
