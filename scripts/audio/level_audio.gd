class_name LevelAudio
extends Node
## Background music and night ambience for a level, made in code so no audio files are needed.
## Builds one seamless 16-second loop (chords, arpeggio, bass, crickets, wind) the first time
## it's needed, then reuses it on every restart.

const RATE := 22050
const BEAT := 0.5  # 120 bpm

@export var music_volume_db: float = -15.0

static var _loop: AudioStreamWAV = null


func _ready() -> void:
	if _loop == null:
		_loop = _build_loop()
	var player := AudioStreamPlayer.new()
	player.stream = _loop
	player.volume_db = music_volume_db
	add_child(player)
	player.play()


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Adds a soft sine note into buf, starting at time t (seconds) and lasting dur seconds.
static func _add_tone(buf: PackedFloat32Array, t: float, dur: float, hz: float, amp: float) -> void:
	var start := int(t * RATE)
	var len := int(dur * RATE)
	var attack := int(0.01 * RATE)
	for i in len:
		var idx := start + i
		if idx < 0 or idx >= buf.size():
			break
		var env := minf(1.0, float(i) / attack) * (1.0 - float(i) / len)
		buf[idx] += sin(TAU * hz * float(i) / RATE) * amp * env


static func _build_loop() -> AudioStreamWAV:
	var bars := 8
	var bar_len := BEAT * 4.0
	var total := bar_len * bars
	var n := int(total * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# Am, F, C, G chords with a matching bass line, one chord per bar (two bars each).
	var chords := [[57, 60, 64], [53, 57, 60], [60, 64, 67], [55, 59, 62]]
	var bass := [45, 41, 48, 43]
	for bar in bars:
		var t0 := bar * bar_len
		var ch: Array = chords[(bar / 2) % 4]
		var root: int = bass[(bar / 2) % 4]
		for note in ch:
			_add_tone(buf, t0, bar_len, _hz(note), 0.05)
		for k in 8:
			var note: int = ch[k % ch.size()] + (12 if k >= 4 else 0)
			_add_tone(buf, t0 + k * BEAT / 2.0, BEAT / 2.0 * 0.85, _hz(note), 0.08)
		for k in 4:
			_add_tone(buf, t0 + k * BEAT, BEAT * 0.8, _hz(root), 0.12)
	# Crickets: quick high chirps, a few each half second.
	var t := 0.0
	while t < total - 0.5:
		for p in 4:
			_add_tone(buf, t + p * 0.045, 0.03, 3900.0, 0.025)
		t += 0.5
	# Wind: soft filtered noise that swells slowly.
	var last := 0.0
	for i in n:
		last = lerpf(last, randf() * 2.0 - 1.0, 0.02)
		buf[i] += last * 0.05 * (0.6 + 0.4 * sin(TAU * float(i) / (RATE * 5.0)))
	# Normalise so the loop never clips.
	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	var scale := 0.75 / maxf(peak, 0.001)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * scale, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav
