# Hover 특수면 설명

> 마우스 오버 팝업에 6면뿐 아니라 **특수면 설명**도 함께 표시.

## 목표

특수면이 있는 주사위에 hover 하면, 기존 6면 미리보기와 함께 해당 특수면(H/L/V·☘ 등)이 **무엇을 하는지** 짧게 설명한다.

## 범위 메모

- 기존: `face_preview_presenter` — 면 위젯만 ([dice-face-hover-preview.md](../../design/systems/dice-face-hover-preview.md))
- 플레이·상점 hover 모두 대상인지 스펙 시 확정
- 설명 문구 출처: 주사위/면 데이터(JSON·Resource) vs UI 하드코드 — 스펙 시 확정
- `preview-non6`(비 6면 UI)과 별개

## 완료 조건 (초안)

- [ ] 특수면이 **없을** 때: 기존과 동일 (면 목록만)
- [ ] 특수면이 **있을** 때: 팝업에 면 + 특수면 설명
- [ ] 플레이(및 합의 시 상점) hover에서 확인 가능

## 구현

- 2026-07-17 백로그·칸반 카드 추가 (`feature/hover-special-face-desc` → main, 검증 대기). UI 미구현.
