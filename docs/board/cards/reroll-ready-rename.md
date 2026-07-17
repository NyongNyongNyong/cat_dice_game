# REROLL_READY 리네이밍 + reroll 잔재 정리

> `READY` 페이즈로 리네임하고 죽은 단일 리롤 preview 코드를 제거.

## 구현

- 2026-07-17 `feature/reroll-ready-rename` → main (검증 대기)
- `RoundPhase.READY` (구 `REROLL_READY`)
- 삭제: `reroll_preview_calculator*` · `reroll_preview_result*`
- RoundController에서 리롤 선택/미리보기 API 제거

## 완료 조건

- [x] 페이즈 이름 의미에 맞게 변경
- [x] 미사용 스크립트 제거
