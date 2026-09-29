extends RefCounted
# Common configurations; no additional chambered round is simulated.
# Belt-fed guns use a chosen belt/box load, not a fixed magazine capacity.
const CAPACITIES := [
	[30, 30, 30, 30, 30, 25, 30, 30, 20, 30],
	[7, 7, 17, 15, 15, 15, 8, 8, 20, 16],
	[100, 200, 100, 100, 100, 40, 50, 30, 47, 47],
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[5, 10, 5, 10, 10, 5, 7, 5, 5, 5]
]
# Desert Eagle .50 AE; M1911 standard 7-round; USP 9mm; CZ75 9mm 16-round.
# Single-use launchers are replaced on reload as a gameplay abstraction.
const RELOAD_SECONDS := [2.3, 1.6, 4.5, 3.0, 2.8]
const SPARE_LOADS: int = 4
