# 시스템 스펙: repo-org-url

> **slug:** `repo-org-url`  
> **상태:** 구현 완료 (검증 대기)

## 목표

GitHub 저장소를 개인 → 조직 `team-sema/cat_dice_game`으로 이전한 뒤, 문서·Pages·원격 URL을 일치시킨다.

## Acceptance Criteria

- [x] README·docs 링크가 `https://github.com/team-sema/cat_dice_game`
- [x] Pages 링크가 `https://team-sema.github.io/cat_dice_game/`
- [x] 로컬 `origin`이 조직 저장소를 가리킴
- [x] 구 `NyongNyongNyong` 문자열 없음

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-18 | 조직 URL·Pages 반영 |
