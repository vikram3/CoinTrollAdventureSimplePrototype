extends Node
## Tiny synthesized sound effects so the prototype has audio feedback
## before real audio assets exist. Autoloaded as "Sfx".

const MIX_RATE := 22050

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -12.0
		add_child(p)
		_players.append(p)
	_streams["coin"] = _make(PackedFloat32Array([1320.0, 1980.0]), 0.06, 0.45, false)
	_streams["jump"] = _make(PackedFloat32Array([420.0, 620.0]), 0.05, 0.3, false)
	_streams["swing"] = _make(PackedFloat32Array([300.0]), 0.07, 0.35, true)
	_streams["hit"] = _make(PackedFloat32Array([220.0, 140.0]), 0.07, 0.5, false)
	_streams["hurt"] = _make(PackedFloat32Array([180.0, 120.0, 90.0]), 0.08, 0.5, false)
	_streams["defeat"] = _make(PackedFloat32Array([520.0, 390.0, 260.0]), 0.06, 0.4, false)
	_streams["block"] = _make(PackedFloat32Array([900.0, 1200.0]), 0.04, 0.4, false)
	_streams["warning"] = _make(PackedFloat32Array([880.0, 0.0, 880.0]), 0.06, 0.3, false)
	_streams["boom"] = _make(PackedFloat32Array([90.0, 70.0, 50.0]), 0.09, 0.6, true)
	_streams["crash"] = _make(PackedFloat32Array([160.0, 110.0]), 0.08, 0.5, true)
	_streams["complete"] = _make(PackedFloat32Array([523.0, 659.0, 784.0, 1046.0]), 0.1, 0.4, false)
	_streams["chime"] = _make(PackedFloat32Array([1760.0, 2637.0]), 0.06, 0.35, false)
	_streams["select"] = _make(PackedFloat32Array([660.0]), 0.04, 0.3, false)


func play(sound: String, pitch_jitter: float = 0.05, pitch_scale: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.pitch_scale = pitch_scale * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


func _make(freqs: PackedFloat32Array, segment: float, volume: float, noise: bool) -> AudioStreamWAV:
	var seg_samples := int(segment * MIX_RATE)
	var total := seg_samples * freqs.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	var idx := 0
	for f in freqs:
		for i in seg_samples:
			var t := float(i) / float(MIX_RATE)
			var env := 1.0 - float(i) / float(seg_samples)
			var s := 0.0
			if f > 0.0:
				s = 0.5 if sin(TAU * f * t) >= 0.0 else -0.5
			if noise:
				s = s * 0.4 + randf_range(-1.0, 1.0) * 0.6
			var v := int(clampf(s * env * volume, -1.0, 1.0) * 32767.0)
			data.encode_s16(idx * 2, v)
			idx += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
