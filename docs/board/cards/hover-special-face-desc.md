# Hover 특수면 설명

> 마우스 오버 팝업에 6면뿐 아니라 **특수면 설명**도 함께 표시. 플레이·상점 공통.

## 목표

특수면이 있는 주사위에 hover 하면, 기존 6면 미리보기와 함께 해당 특수면(H/L/V·☘ 등)이 **무엇을 하는지** 짧게 설명한다.

## 완료 조건

- [x] 특수면이 **없을** 때: 기존과 동일 (면 목록만)
- [x] 특수면이 **있을** 때: 팝업에 면 + 특수면 설명
- [x] 플레이·상점 hover에서 확인 가능
- [x] 마우스 근처 표시 · 화면 밖 클램프
- [x] 상점 PopupOverlay 전체화면 (좌표 깨짐 수정)

## 구현

- 2026-07-18 `feature/hover-special-face-desc` → main (검증 대기)
- `FaceProperty.get_description()` + `face_preview_presenter` 설명 영역
- 상점 overlay·전역 마우스 좌표
- 스펙: `docs/design/systems/hover-special-face-desc.md`
