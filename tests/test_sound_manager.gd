class_name TestSoundManager
extends RefCounted

## Unit tests for SoundManager procedural audio synthesis engine.

const SoundManager = preload("res://scripts/core/sound_manager.gd")

static func run(runner) -> void:
	test_instantiation_and_singleton(runner)
	test_procedural_wav_streams(runner)
	test_sound_toggle_and_playback(runner)

static func test_instantiation_and_singleton(runner) -> void:
	var sm: SoundManager = SoundManager.new()
	runner.assert_not_null(sm, "SoundManager should instantiate successfully")
	runner.assert_eq(SoundManager.instance, sm, "SoundManager.instance singleton should point to active instance")
	sm.queue_free()

static func test_procedural_wav_streams(runner) -> void:
	var sm: SoundManager = SoundManager.new()
	# Call _ready manually or build sounds
	sm._build_all_sounds()

	runner.assert_not_null(sm.stream_snap, "Snap stream should be generated")
	runner.assert_gt(sm.stream_snap.data.size(), 0, "Snap stream data must not be empty")
	runner.assert_eq(sm.stream_snap.mix_rate, 44100, "Snap sample rate should be 44.1kHz")

	runner.assert_not_null(sm.stream_rotate, "Rotate stream should be generated")
	runner.assert_gt(sm.stream_rotate.data.size(), 0, "Rotate stream data must not be empty")

	runner.assert_not_null(sm.stream_create, "Create pop stream should be generated")
	runner.assert_gt(sm.stream_create.data.size(), 0, "Create stream data must not be empty")

	runner.assert_not_null(sm.stream_delete, "Delete swoosh stream should be generated")
	runner.assert_gt(sm.stream_delete.data.size(), 0, "Delete stream data must not be empty")

	runner.assert_not_null(sm.stream_click, "Click stream should be generated")
	runner.assert_gt(sm.stream_click.data.size(), 0, "Click stream data must not be empty")

	runner.assert_not_null(sm.stream_fanfare, "Fanfare stream should be generated")
	runner.assert_gt(sm.stream_fanfare.data.size(), 0, "Fanfare stream data must not be empty")

	sm.queue_free()

static func test_sound_toggle_and_playback(runner) -> void:
	var sm: SoundManager = SoundManager.new()
	sm._build_all_sounds()

	var emitted_values: Array = []
	sm.sound_toggled.connect(func(val: bool): emitted_values.append(val))

	sm.sound_enabled = false
	runner.assert_false(sm.sound_enabled, "Sound should be disabled")
	runner.assert_eq(emitted_values.size(), 1, "Should emit once on disable")
	runner.assert_false(emitted_values[0], "Emitted value should be false")

	# Safe playback while muted
	sm.play_snap()
	sm.play_click()
	sm.play_fanfare()

	sm.sound_enabled = true
	runner.assert_true(sm.sound_enabled, "Sound should be enabled")
	runner.assert_eq(emitted_values.size(), 2, "Should emit second time on enable")
	runner.assert_true(emitted_values[1], "Second emitted value should be true")

	sm.queue_free()
