extends Node

## Headless Test Runner for Triangle Art

const TestTriangleMath = preload("res://tests/test_triangle_math.gd")
const TestCommandManager = preload("res://tests/test_command_manager.gd")
const TestTriangleNode = preload("res://tests/test_triangle_node.gd")
const TestPngExport = preload("res://tests/test_png_export.gd")
const TestSoundManager = preload("res://tests/test_sound_manager.gd")
const TestPuzzleEvaluator = preload("res://tests/test_puzzle_evaluator.gd")

var passed_count: int = 0
var failed_count: int = 0
var test_failures: Array[String] = []

func _ready() -> void:
	print("==================================================")
	print("  Starting Triangle Art Headless Test Suite")
	print("==================================================")

	# 1. Triangle Math Tests
	print("\n[Suite] Testing TriangleMath...")
	TestTriangleMath.run(self)

	# 2. Command Manager Tests
	print("[Suite] Testing CommandManager...")
	TestCommandManager.run(self)

	# 3. Triangle Node Tests
	print("[Suite] Testing TriangleNode...")
	TestTriangleNode.run(self)

	# 4. Sound Manager Tests
	print("[Suite] Testing SoundManager...")
	TestSoundManager.run(self)

	# 5. Puzzle Evaluator Tests
	print("[Suite] Testing PuzzleEvaluator...")
	TestPuzzleEvaluator.run(self)

	# 6. PNG Export Tests
	print("[Suite] Testing PngExport...")
	await TestPngExport.run(self)

	# Summary
	print("\n==================================================")
	print("  Test Results: %d Passed, %d Failed" % [passed_count, failed_count])
	print("==================================================")

	if failed_count > 0:
		print("\nFailures:")
		for f in test_failures:
			print("  ❌ " + f)
		get_tree().quit(1)
	else:
		print("  ✅ All tests passed successfully!")
		get_tree().quit(0)

func assert_true(cond: bool, msg: String = "") -> void:
	if cond:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert True failed: " + msg)

func assert_false(cond: bool, msg: String = "") -> void:
	if not cond:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert False failed: " + msg)

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual == expected:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Equal failed: %s (Expected: %s, Got: %s)" % [msg, str(expected), str(actual)])

func assert_float_approx(actual: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	if absf(actual - expected) <= eps:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Approx failed: %s (Expected: %f, Got: %f)" % [msg, expected, actual])

func assert_not_null(val: Variant, msg: String = "") -> void:
	if val != null:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Not Null failed: " + msg)

func assert_gt(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual > expected:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Greater Than failed: %s (Got: %s, Threshold: %s)" % [msg, str(actual), str(expected)])

func assert_ge(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual >= expected:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Greater Equal failed: %s (Got: %s, Threshold: %s)" % [msg, str(actual), str(expected)])

func assert_lt(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual < expected:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Less Than failed: %s (Got: %s, Threshold: %s)" % [msg, str(actual), str(expected)])

func assert_le(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual <= expected:
		passed_count += 1
	else:
		failed_count += 1
		test_failures.append("Assert Less Equal failed: %s (Got: %s, Threshold: %s)" % [msg, str(actual), str(expected)])

