# feature/ui-editor-friendly

> 사람이 Godot 에디터에서 UI를 재배치·장식할 때 GDScript를 고치지 않아도 되게 만든다.

## 배경

노드 참조는 이미 전부 `%UniqueName`이라 계층 변경에 안전하다. 실제 장애물은 다른 곳이었다.

- 코드가 `custom_minimum_size`·StyleBox를 런타임에 덮어써 에디터 설정이 무시됨
- 코드가 컨테이너 자식을 통째로 `queue_free` → 장식 노드·AnimationPlayer 추가 불가
- 상점 카드·풀 칸·툴팁·히스토리 행이 `.tscn` 없이 코드로만 조립돼 에디터에서 열 수 없음
- 목표 진행 구간·보상 골드 계산이 `run_scene.gd`(UI)에 있음

## AC

- [ ] 에디터에서 지정한 최소 크기·StyleBox가 실행 후에도 유지된다 (상태 하이라이트는 예외)
- [ ] 코드 소유 컨테이너에 장식 노드를 넣어도 갱신 시 삭제되지 않는다
- [ ] 상점 카드·풀 칸·히스토리 행·호버 툴팁을 에디터에서 열어 편집할 수 있다
- [ ] 보상·구간 계산이 `scripts/core/`로 이동하고 UI에는 연출만 남는다
- [ ] 게임 규칙·점수·주사위 동작에 변화가 없다

## 구현

- 스펙: `docs/design/systems/ui-editor-friendly.md`
- Task: `docs/design/tasks/ui-editor-friendly-tasks.md`
- 새 씬: `shop_offer_die` · `shop_pool_cell` · `active_hand_row` · `face_preview_tooltip`
- 새 테스트: `scripts/core/ui_scene_spec_test.gd` (핵심 노드 이름 회귀)
- 2026-07-26 headless 검증 통과 — 플레이 검증 대기
- 2026-07-26 `feature/ui-editor-friendly` → main (검증 대기)
- 잔여 ideas: `run-scene-hud-split` · `sidebar-layout-coupling` · `run-scene-overlay-rename` · `ui-dead-code-cleanup` · `roll-lever-tool-preview`
