extends RefCounted
# Cached procedural shots shared by the player and spatial bot emitters.
static var cache: Dictionary = {}
static func shot(category: int) -> AudioStreamWAV:
	if cache.has(category):
		return cache[category]
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var duration: float = [.14,.10,.18,.30,.26][clampi(category,0,4)]
	var frequency: float = [180,280,120,65,95][clampi(category,0,4)]
	var samples := int(duration*stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(samples*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 581+category
	for i in range(samples):
		var t := float(i)/stream.mix_rate
		var envelope := pow(1.0-float(i)/samples,3)*minf(1,t/.001)
		var value := (rng.randf_range(-1,1)*.65+sin(t*TAU*frequency)*.35)*envelope
		bytes.encode_s16(i*2,int(value*24000))
	stream.data = bytes
	cache[category] = stream
	return stream