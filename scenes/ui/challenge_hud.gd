class_name ChallengeHUD
extends PanelContainer

## Floating Gamification HUD for Puzzle Challenge Mode.
## Displays target template name, live matching accuracy bar, 3-star rating, and victory celebration.

signal challenge_closed
signal next_challenge_requested
signal challenge_completed(percentage: int, stars: int)

@onready var lbl_title: Label = %LblTitle
@onready var lbl_accuracy: Label = %LblAccuracy
@onready var progress_accuracy: ProgressBar = %ProgressAccuracy
@onready var star_1: Label = %Star1
@onready var star_2: Label = %Star2
@onready var star_3: Label = %Star3
@onready var lbl_counts: Label = %LblCounts
@onready var btn_close: Button = %BtnClose

@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var lbl_victory_score: Label = %LblVictoryScore
@onready var lbl_victory_stars: Label = %LblVictoryStars
@onready var btn_keep_editing: Button = %BtnKeepEditing
@onready var btn_next_stage: Button = %BtnNextStage

var current_template_name: String = ""
var is_completed: bool = false

func _ready() -> void:
	btn_close.pressed.connect(func(): challenge_closed.emit())
	btn_keep_editing.pressed.connect(func(): victory_panel.visible = false)
	btn_next_stage.pressed.connect(func():
		victory_panel.visible = false
		next_challenge_requested.emit()
	)
	victory_panel.visible = false
	_update_stars(0)

func set_challenge(template_name: String) -> void:
	current_template_name = template_name
	is_completed = false
	victory_panel.visible = false
	lbl_title.text = "★ 챌린지: " + template_name
	progress_accuracy.value = 0
	lbl_accuracy.text = "일치율: 0%"
	lbl_counts.text = "삼각형 준비 중..."
	_update_stars(0)

func update_progress(eval_result: Dictionary) -> void:
	var accuracy: float = eval_result.get("accuracy", 0.0)
	var pct: int = eval_result.get("percentage", 0)
	var stars: int = eval_result.get("stars", 0)
	var t_count: int = eval_result.get("template_count", 0)
	var u_count: int = eval_result.get("user_count", 0)

	progress_accuracy.value = pct
	lbl_accuracy.text = "일치율: %d%%" % pct
	lbl_counts.text = "삼각형: %d / %d" % [u_count, t_count]
	_update_stars(stars)

	if eval_result.get("passed", false) and not is_completed:
		is_completed = true
		_trigger_victory(pct, stars)

func _update_stars(star_count: int) -> void:
	var col_on: Color = Color("#FFD700") # Gold
	var col_off: Color = Color(0.35, 0.42, 0.55, 0.4)

	star_1.modulate = col_on if star_count >= 1 else col_off
	star_2.modulate = col_on if star_count >= 2 else col_off
	star_3.modulate = col_on if star_count >= 3 else col_off

func _trigger_victory(final_pct: int, stars: int) -> void:
	lbl_victory_score.text = "최종 일치율: %d%%" % final_pct
	var star_str: String = ""
	for i in range(stars):
		star_str += "★ "
	for i in range(3 - stars):
		star_str += "☆ "
	lbl_victory_stars.text = star_str.strip_edges()
	victory_panel.visible = true

	# Play celebration sound via SoundManager
	if SoundManager.instance:
		SoundManager.instance.play_fanfare()
	challenge_completed.emit(final_pct, stars)
