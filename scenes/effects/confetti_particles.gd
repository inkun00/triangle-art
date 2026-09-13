class_name ConfettiParticles
extends Node2D

## High-performance vector confetti particle system for Triangle Art.
## Emits colorful spinning geometric triangles with physics gravity, flutter, and decay.

signal finished

class ParticlePiece:
	var pos: Vector2
	var vel: Vector2
	var rot: float
	var rot_vel: float
	var size: float
	var color: Color
	var life: float
	var max_life: float
	var flutter_phase: float

var _particles: Array[ParticlePiece] = []
var _is_active: bool = false

const COLORS: Array[Color] = [
	Color("#FF4D6D"), # Hot Pink
	Color("#FF9E00"), # Amber
	Color("#FFD000"), # Gold
	Color("#00E096"), # Emerald
	Color("#00B4D8"), # Cyan
	Color("#7209B7"), # Purple
	Color("#4CC9F0"), # Sky Blue
	Color("#F72585"), # Magenta
	Color("#FFFFFF")  # Crisp White
]

func _ready() -> void:
	z_index = 100 # Always on top of canvas and UI

func explode(center: Vector2, count: int = 90) -> void:
	_particles.clear()
	_is_active = true

	for i in range(count):
		var p: ParticlePiece = ParticlePiece.new()
		p.pos = center + Vector2(randf_range(-40.0, 40.0), randf_range(-20.0, 20.0))

		# Fountain upward angle: -140 deg to -40 deg
		var angle: float = deg_to_rad(randf_range(-145.0, -35.0))
		var speed: float = randf_range(280.0, 650.0)
		p.vel = Vector2(cos(angle), sin(angle)) * speed

		p.rot = randf_range(0.0, TAU)
		p.rot_vel = randf_range(-8.0, 8.0)
		p.size = randf_range(7.0, 16.0)
		p.color = COLORS[randi() % COLORS.size()]
		p.max_life = randf_range(2.0, 3.2)
		p.life = p.max_life
		p.flutter_phase = randf_range(0.0, TAU)
		_particles.append(p)

	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not _is_active:
		return

	var gravity: float = 480.0
	var alive_count: int = 0

	for p in _particles:
		if p.life > 0.0:
			p.life -= delta
			p.flutter_phase += delta * 6.0
			p.vel.y += gravity * delta
			p.vel.x *= (1.0 - 0.4 * delta) # Air resistance
			p.pos += p.vel * delta
			p.pos.x += sin(p.flutter_phase) * 35.0 * delta # Fluttering motion
			p.rot += p.rot_vel * delta
			alive_count += 1

	queue_redraw()

	if alive_count == 0:
		_is_active = false
		set_process(false)
		finished.emit()

func _draw() -> void:
	if not _is_active:
		return

	for p in _particles:
		if p.life <= 0.0:
			continue

		var progress: float = 1.0 - (p.life / p.max_life)
		var alpha: float = 1.0
		if progress > 0.7:
			alpha = (1.0 - progress) / 0.3

		var draw_color: Color = p.color
		draw_color.a *= alpha

		# Draw miniature rotating triangle
		var s: float = p.size * (1.0 - progress * 0.25)
		var v0: Vector2 = Vector2(0.0, -s).rotated(p.rot)
		var v1: Vector2 = Vector2(-s * 0.866, s * 0.5).rotated(p.rot)
		var v2: Vector2 = Vector2(s * 0.866, s * 0.5).rotated(p.rot)

		var poly: PackedVector2Array = PackedVector2Array([
			p.pos + v0,
			p.pos + v1,
			p.pos + v2
		])

		draw_colored_polygon(poly, draw_color)
