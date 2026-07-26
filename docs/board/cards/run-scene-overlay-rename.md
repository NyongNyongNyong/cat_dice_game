# run_scene 오버레이 변수명 정리

> `%ScoreOverlay` / `%PopupOverlay`와 어긋난 변수명을 맞춘다.

## 배경

`run_scene.gd`에서:

- `_popup_overlay` → 실제 노드 `%ScoreOverlay` (점수 연출)
- `_dice_popup_layer` → 실제 노드 `%PopupOverlay` (면 호버 툴팁)

에디터에서 오버레이를 편집할 때 헷갈리기 쉽다. 리네임만으로 끝나는 작은 정리 작업.

## 완료 조건

- [ ] 변수명이 노드 Unique Name과 대응한다 (예: `_score_overlay`, `_popup_overlay`)
- [ ] 호출부·presenter `setup` 인자 이름이 따라 맞춰졌다
