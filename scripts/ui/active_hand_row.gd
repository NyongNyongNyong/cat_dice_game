class_name ActiveHandRow
extends HBoxContainer

## 히스토리 한 줄. 표시만 담당하고 점수·족보 계산은 하지 않는다.

@onready var _hand_label: Label = %HandLabel
@onready var _score_label: Label = %ScoreLabel


func set_entry(index: int, hand_text: String, score: int) -> void:
	_hand_label.text = "%02d. %s" % [index, hand_text]
	_score_label.text = "+%d" % score
