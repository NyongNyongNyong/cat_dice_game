# 시스템 스펙: 주사위 면 Hover 미리보기 (플레이 화면)

> **유형:** 구현 설계 (UI 배선)
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §4 — 배치·굴림
> **면·해석:** [dice-resources.md](dice-resources.md) — `DiceResource.get_faces()`
> **관련(이전):** [dice-hover-reroll-preview.md](dice-hover-reroll-preview.md) — v0.1 리롤 Preview (히스토리)
> **상태:** 구현 중
> **slug:** `dice-face-hover-preview`

플레이(보드) 화면에서 보드 칸·로스터 트레이의 주사위에 **마우스를 올리면 그 주사위의 면(기본 6면)** 을 미니 툴팁으로 보여준다. 상점 화면에는 이미 있는 기능을 플레이 화면에도 배선한다.

---

## 1. 배경 (왜 지금 안 뜨는가)

면 Hover 툴팁은 `RerollPreviewPresenter`(이름만 리롤, 실제로는 면 미리보기 툴팁)가 담당한다.

- **상점(`dice_shop_presenter.gd`):** offer·roster 주사위에 `mouse_entered`/`mouse_exited` 연결 → 정상 작동.
- **플레이(`run_scene.gd`):** presenter를 `set_active(false)`로 두고, 보드/트레이 slot에 hover 배선이 없어 **면 툴팁이 뜨지 않음.**

리롤 경제(v0.1)를 걷어내는 과정에서 플레이 화면 hover가 비활성 상태로 남았다.

---

## 2. 리네이밍 (면 Preview로 정리)

Hover 툴팁 담당 스크립트·노드를 리롤과 무관한 이름으로 정리한다.

| 이전 | 이후 |
|------|------|
| `scripts/ui/reroll_preview_presenter.gd` | `scripts/ui/face_preview_presenter.gd` |
| 노드 `RerollPreviewPresenter` (run/shop 씬) | `FacePreviewPresenter` |
| `run_scene.gd` `_reroll_preview_presenter` | `_face_preview_presenter` |

**범위 밖 (건드리지 않음):** `reroll_preview_calculator.gd`, `reroll_preview_result.gd`, `reroll_preview_calculator_spec_test.gd`, `round_controller.get_reroll_preview()` — 이름은 같지만 **리롤 점수 델타 계산** 로직이라 이 feature와 무관. 완전 제거는 backlog의 별도 정리 과제.

---

## 3. 동작

보드 칸·트레이 칩의 주사위에 Hover 시 해당 주사위 `DiceResource.get_faces()` 전체를 미니 `dice.tscn`으로 툴팁에 표시한다.

| 항목 | 규칙 |
|------|------|
| **대상** | 보드에 배치된 주사위 · 트레이의 미배치 주사위 |
| **내용** | 해당 주사위의 면 전체 (기본 6면), 미니 주사위 위젯 |
| **점수 델타** | 표시하지 않음 (면 목록만) |
| **앵커** | Hover된 주사위 위젯 중심 상단 (presenter 기존 로직) |
| **숨김** | `mouse_exited` 시 |

### 3.1 활성 조건

| 조건 | Hover 툴팁 |
|------|-----------|
| 레버 정지(`_is_lever_stopped()`) + phase `IDLE`/`REROLL_READY` | **활성** |
| `ROLLING` / `SCORING` / 레버 굴림 중 | 비표시 |
| 잠금 칸(`is_slot_unlocked` false) | 비표시 (locked slot은 마우스 입력 무시) |
| 빈 칸 (주사위 없음) | 비표시 |

---

## 4. 구현

| 파일 | 변경 |
|------|------|
| `scripts/ui/face_preview_presenter.gd` | (리네이밍) 기존 `reroll_preview_presenter.gd` 내용 유지 |
| `scripts/ui/run_scene.gd` | presenter 참조·활성화, 보드/트레이 slot `mouse_entered`/`mouse_exited` 배선, `_can_hover_dice_faces()` 가드 |
| `scripts/ui/shop_scene.gd` | presenter 참조 이름만 갱신 |
| `scenes/game/run_scene.tscn` · `shop_scene.tscn` | 노드 이름·스크립트 경로 갱신 |

- 보드 칸은 `_build_board()`에서 slot 생성 시 1회 연결(노드 영속). 트레이 칩은 `_refresh_tray()`에서 매번 생성되므로 그때 연결.
- Hover 핸들러는 `RunManager.get_owned_index_at(cell)` / 트레이 `slot_index`로 **실시간** 주사위 리소스를 조회 → 배치 변경 후에도 정확.
- `show_die_faces(dice_view, faces, faces, -1)` — 상점과 동일 호출.

---

## 5. 비범위

- 점수 델타(`▲▼`) 표시 부활, 리롤 로직, `reroll_preview_calculator*` 제거, 드래그 앤 드롭.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-02 | 초안 — 플레이 화면 보드/트레이 면 Hover 배선 + presenter 리네이밍 |
