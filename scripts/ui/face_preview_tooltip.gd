class_name FacePreviewTooltip
extends PanelContainer

## 주사위 면 미리보기 툴팁의 껍데기. 내용 채우기는 face_preview_presenter가 한다.

@onready var content: VBoxContainer = %Content
@onready var faces_row: HBoxContainer = %FacesRow
@onready var desc_box: VBoxContainer = %DescBox
