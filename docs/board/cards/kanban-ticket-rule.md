# 칸반 티켓 자동 관리 규칙

> `/feature`·`/push` 때 `docs/board` 카드를 에이전트가 자동 갱신.

## 구현

- 2026-07-17 `feature/kanban-ticket-rule` → main (검증 대기)
- 규칙: `.cursor/rules/kanban-tickets.mdc`
- `/push` 기본 도착 열: `review` (`done`은 사람 검증 후)

## 같이 한 보드 정리

- `luck-sources`: `doing` → `ideas` (콘텐츠 추가 시 따라오는 후보)
