class_name PuzzleEvaluator
extends RefCounted

## Evaluates the matching accuracy (0.0 to 1.0) between user canvas triangles and template silhouettes.
## Used for the interactive Puzzle / Challenge Gamification mode.

const TriangleMath = preload("res://scripts/core/triangle_math.gd")

## Evaluates accuracy (0.0 to 1.0) between active canvas triangles and a template definition.
static func evaluate_accuracy(canvas_triangles: Array, template_data: Variant) -> Dictionary:
	var template_items: Array = []
	if template_data is Array:
		template_items = template_data
	elif template_data is Dictionary and template_data.has("triangles"):
		template_items = template_data["triangles"]

	if template_items.is_empty():
		return {"accuracy": 0.0, "percentage": 0, "stars": 0, "passed": false, "template_count": 0, "user_count": canvas_triangles.size()}
	var total_target_triangles: int = template_items.size()
	var user_count: int = canvas_triangles.size()

	if user_count == 0:
		return {"accuracy": 0.0, "percentage": 0, "stars": 0, "passed": false, "template_count": total_target_triangles, "user_count": 0}

	# 1. Collect world-space polygons of template
	var target_tris: Array[Array] = []
	var min_bound: Vector2 = Vector2(INF, INF)
	var max_bound: Vector2 = Vector2(-INF, -INF)

	for item in template_items:
		var pos: Vector2 = item["pos"]
		var pa: Vector2 = pos + item["a"]
		var pb: Vector2 = pos + item["b"]
		var pc: Vector2 = pos + item["c"]
		target_tris.append([pa, pb, pc])

		for p in [pa, pb, pc]:
			min_bound.x = minf(min_bound.x, p.x)
			min_bound.y = minf(min_bound.y, p.y)
			max_bound.x = maxf(max_bound.x, p.x)
			max_bound.y = maxf(max_bound.y, p.y)

	# 2. Collect world-space polygons of user triangles
	var user_tris: Array[Array] = []
	for t in canvas_triangles:
		if is_instance_valid(t) and t is TriangleNode:
			var pa: Vector2 = t.position + t.vertex_a
			var pb: Vector2 = t.position + t.vertex_b
			var pc: Vector2 = t.position + t.vertex_c
			user_tris.append([pa, pb, pc])

	# 3. Sample points across the target template silhouette
	var sample_points: Array[Vector2] = []
	var step: float = maxf((max_bound.x - min_bound.x) / 36.0, 12.0)
	var sy: float = min_bound.y + step * 0.5
	while sy <= max_bound.y:
		var sx: float = min_bound.x + step * 0.5
		while sx <= max_bound.x:
			var pt: Vector2 = Vector2(sx, sy)
			for tri in target_tris:
				if TriangleMath.is_point_in_triangle(pt, tri[0], tri[1], tri[2]):
					sample_points.append(pt)
					break
			sx += step
		sy += step

	if sample_points.is_empty():
		return {"accuracy": 0.0, "percentage": 0, "stars": 0, "passed": false, "template_count": total_target_triangles, "user_count": user_count}

	# 4. Check how many target sample points are covered by user triangles
	var covered_count: int = 0
	for pt in sample_points:
		for utri in user_tris:
			if TriangleMath.is_point_in_triangle(pt, utri[0], utri[1], utri[2]):
				covered_count += 1
				break

	var coverage_ratio: float = float(covered_count) / float(sample_points.size())

	# 5. Check triangle count match & outside penalty
	var count_diff: int = abs(user_count - total_target_triangles)
	var count_penalty: float = clampf(float(count_diff) * 0.05, 0.0, 0.25)

	# Check points inside user triangles that are outside the target
	var outside_samples: int = 0
	var user_sample_count: int = 0
	for utri in user_tris:
		var u_c: Vector2 = (utri[0] + utri[1] + utri[2]) / 3.0
		user_sample_count += 1
		var in_target: bool = false
		for ttri in target_tris:
			if TriangleMath.is_point_in_triangle(u_c, ttri[0], ttri[1], ttri[2]):
				in_target = true
				break
		if not in_target:
			outside_samples += 1

	var outside_penalty: float = 0.0
	if user_sample_count > 0:
		outside_penalty = float(outside_samples) / float(user_sample_count) * 0.2

	var final_accuracy: float = clampf(coverage_ratio - count_penalty - outside_penalty, 0.0, 1.0)

	var stars: int = 0
	if final_accuracy >= 0.92:
		stars = 3
	elif final_accuracy >= 0.78:
		stars = 2
	elif final_accuracy >= 0.58:
		stars = 1

	var passed: bool = final_accuracy >= 0.90

	return {
		"accuracy": final_accuracy,
		"percentage": int(roundf(final_accuracy * 100.0)),
		"stars": stars,
		"passed": passed,
		"template_count": total_target_triangles,
		"user_count": user_count
	}
