# 시스템 스펙: REROLL_READY 리네이밍 + reroll 잔재 정리

> **slug:** `reroll-ready-rename`  
> **상태:** 구현 중  
> **관련:** [v0.2-board-luck.md](v0.2-board-luck.md) B2 · [dice-face-hover-preview.md](dice-face-hover-preview.md)

---

## 목적

단일 주사위 리롤은 폐기됨. 페이즈 이름 `REROLL_READY`와 미사용 `reroll_preview_*` API/파일을 정리한다.

## 변경

| 항목 | 내용 |
|------|------|
| Phase | `REROLL_READY` → **`READY`** (점수 후 · 다음 전체 굴림/상점 대기) |
| 삭제 | `reroll_preview_calculator.gd` · `reroll_preview_result.gd` · 스펙 테스트 |
| RoundController | `can_reroll_preview` / `select_die` / `get_reroll_preview` / `get_reroll_face_values` / 선택·리롤 시그널·필드 제거 |

## Acceptance Criteria

- [x] 코드에 `REROLL_READY` enum 부재, `READY` 사용
- [x] `reroll_preview_calculator*` 파일 없음
- [x] UI·보드 편집·hover 가드가 `IDLE`/`READY`에서 동작
- [x] 관련 스펙 테스트 통과
- [x] Godot 족보/점수 공식 미변경

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | 구현 — READY 리네임 + dead reroll 제거 |
