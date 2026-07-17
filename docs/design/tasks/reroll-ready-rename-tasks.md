# Tasks: reroll-ready-rename

> **스펙:** [reroll-ready-rename.md](../systems/reroll-ready-rename.md)

## Task 1. Phase 리네임

- [x] `round_phase.gd`: `READY`
- [x] `round_controller.gd` · `run_scene.gd` 참조 갱신

## Task 2. Dead code 제거

- [x] `reroll_preview_calculator*` · `reroll_preview_result*` 삭제
- [x] RoundController 리롤 미리보기/선택 API 제거
- [x] `dice_resource_spec_test` 해당 케이스 제거

## Task 3. 문서·보드

- [x] 현행 스펙 문구 `READY`로 맞춤 (호버·보드·백로그)
- [x] README 칸반 링크 상단
- [x] 티켓 `reroll-ready-rename` → review; `script-preloads` → ideas

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | 완료 |
