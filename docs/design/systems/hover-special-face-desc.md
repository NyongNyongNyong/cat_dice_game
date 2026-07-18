# 시스템 스펙: Hover 특수면 설명

> **slug:** `hover-special-face-desc`  
> **상태:** 구현 완료 (검증 대기)  
> **관련:** [dice-face-hover-preview.md](dice-face-hover-preview.md) · [dice-resources.md](dice-resources.md)

---

## 목표

주사위 hover 툴팁에 **6면 미니 미리보기**와 함께, 특수면이 있으면 **효과 설명**을 표시한다.  
**플레이·상점** 모두 — 공통 `FacePreviewPresenter`를 쓰므로 presenter만 확장한다.

## 동작

| 조건 | 표시 |
|------|------|
| 숫자면만 | 기존과 동일 — 면 행만 |
| 특수면 포함 | 면 행 + 아래 설명 줄 (`글리프 — 설명`) |
| 동일 특수면 여러 개 | 설명은 **종류당 1줄** (중복 제거) |
| 가장자리 hover | 툴팁이 팝업 레이어(화면) 밖으로 나가지 않게 클램프 |
| 앵커 | **마우스 커서 근처** (위 우선, 잘리면 아래) — 주사위 중심 아님 |

### 설명 출처

각 `FaceProperty.get_description()` (한국어 한 줄). 글리프는 기존 `get_display_text`.

| property | 글리프 | 설명 |
|----------|--------|------|
| `change_to_highest` | H | 보드의 다른 숫자 면 중 가장 큰 값으로 바뀝니다. |
| `change_to_lowest` | L | 보드의 다른 숫자 면 중 가장 작은 값으로 바뀝니다. |
| `change_to_missing` | V | 보드에 없는 1~6 숫자로 바뀝니다. |
| `luck_bonus` | ☘ | 점수에 포함되지 않고, 굴림 후 행운이 증가합니다. |

## 구현 위치

| 파일 | 역할 |
|------|------|
| `scripts/core/face_properties/*.gd` | `get_description()` |
| `scripts/ui/face_preview_presenter.gd` | 툴팁에 설명 VBox |
| 플레이·상점 call site | 변경 없음 (동일 `show_die_faces`) |

## Acceptance Criteria

- [x] 특수면 없으면 면만
- [x] 특수면 있으면 면 + 설명
- [x] 플레이·상점 hover 동일
- [x] 설명은 property에서 제공 (presenter 하드코드 목록 없음)
- [x] 가장자리(왼쪽 등)에서도 툴팁이 화면 밖으로 잘리지 않음
- [x] 툴팁은 마우스 근처에 표시

## 비범위

- 비 6면 UI (`preview-non6`)
- JSON에 description 필드 추가 (추후 확장 가능)

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-18 | 플레이·상점 공통 hover 특수면 설명 |
| 2026-07-18 | 가장자리 툴팁 클램프 |
| 2026-07-18 | 앵커를 마우스 근처로 변경 |
| 2026-07-18 | 상점 PopupOverlay 전체화면 + 전역 마우스 좌표 |
