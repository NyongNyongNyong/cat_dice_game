# Tasks: ui-editor-friendly

> **스펙:** [ui-editor-friendly.md](../systems/ui-editor-friendly.md)

## Task 1. 코드가 에디터 값을 덮어쓰지 않게

- [x] `dice_slot` — 기본 StyleBox를 `.tscn`으로, 상태 색만 코드 오버라이드
- [x] `shop_pool_cell` · `shop_offer_die` — 같은 방식
- [x] `custom_minimum_size`는 씬에 값이 없을 때만 코드가 설정
- [x] `%TargetProgressBar` fill — 씬 스타일 복제 후 색만 교체
- [x] `roll_lever` 색·치수를 `@export`로 노출

## Task 2. 코드 소유 컨테이너 안전화

- [x] `main.gd` — 직전 씬만 정리 (`%UI` 전체 삭제 금지)
- [x] `run_scene.gd` — `_board_cells` · `_tray_chips`만 삭제
- [x] `score_phase_presenter.gd` — 띄운 팝업만 추적·삭제
- [x] `active_hands_presenter.gd` · `dice_shop_presenter.gd` — 생성 노드만 삭제

## Task 3. 반복 UI 씬 분리

- [x] `scenes/ui/shop_offer_die.tscn`
- [x] `scenes/ui/shop_pool_cell.tscn`
- [x] `scenes/ui/active_hand_row.tscn` (+ `active_hand_row.gd`)
- [x] `scenes/ui/face_preview_tooltip.tscn` (+ `face_preview_tooltip.gd`)
- [x] "기록 없음" 안내를 `%ActiveHandsEmptyHint` 노드로

## Task 4. 규칙 계산 분리 · 중복 갱신 정리

- [x] 임계 구간·보상 계산을 `gold_calculator.gd`로 이동
- [x] `run_scene.gd`·`shop_scene.gd`의 이중 라벨 대입 제거

## Task 5. 검증

- [x] `ui_scene_spec_test.gd` — 핵심 노드 이름 회귀 테스트 (의도적 실패로 동작 확인)
- [x] `gold_calculator_spec_test.gd` — 구간·보상 누적 케이스 추가
- [x] 스펙 테스트 9종 통과
- [x] main · run_scene · shop_scene headless 부팅 (30프레임, 오류 0)
- [x] `%NextFloorButton`을 새 Panel + MarginContainer 아래로 옮겨 부팅 확인 후 원복
- [ ] 사람이 직접 플레이 검증 (드래그·레버·툴팁·연출)

## AC

- [x] 에디터에서 지정한 최소 크기·StyleBox가 실행 후에도 유지된다
- [x] 코드 소유 컨테이너에 장식 노드를 넣어도 갱신 시 삭제되지 않는다
- [x] 상점 카드·풀 칸·히스토리 행·호버 툴팁을 에디터에서 열 수 있다
- [x] 보상·구간 계산이 `scripts/core/`로 이동
- [ ] 게임 동작에 변화가 없다 — 정적·부팅 검증 통과, 플레이 검증 대기

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-26 | Task 1~5 구현 (플레이 검증 제외) |
