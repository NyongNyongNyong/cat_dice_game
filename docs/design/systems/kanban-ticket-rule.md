# 칸반 티켓 자동 관리 규칙

> **문서 유형:** 워크플로 스펙  
> **관련:** [kanban-v2.md](kanban-v2.md) · `.cursor/rules/kanban-tickets.mdc`  
> **상태:** v1  
> **구현:** Cursor rules + `/push`·`/feature` 스킬

---

## 목적

개발 아이템을 `docs/board/` 티켓(카드)으로 관리하고, `/feature`·`/push` 때 에이전트가 열·MD를 자동 갱신한다.

---

## 동작

| 시점 | 동작 |
|------|------|
| `/feature` | slug 카드 찾거나 생성 → `speccing` 또는 `doing` |
| `/push` | 해당 카드 → `review` + MD 이력, 커밋에 포함 |
| 사람 검증 OK | → `done` (에이전트는 지시 있을 때만) |
| `/push`만으로 `done` | **금지** |

카드 id = feature slug. 보드 정본: `cards.json` + `cards/<id>.md`.

---

## Acceptance Criteria

- [x] `.cursor/rules/kanban-tickets.mdc` alwaysApply
- [x] `/push`·start-feature 스킬에 티켓 단계 포함
- [x] `luck-sources`를 `ideas`로 재배치 (단독 WIP 아님)
- [x] Godot/점수 미변경

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | v1 — 티켓 규칙 + push/feature 연동 |
