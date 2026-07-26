# 시스템 스펙: 에디터에서 UI 편집하기

> **slug:** `ui-editor-friendly`
> **상태:** 구현 완료 (검증 대기)
> **코드 정본:** `scripts/ui/*.gd` · `scenes/ui/*.tscn` · `scripts/core/ui_scene_spec_test.gd`

사람이 Godot 에디터에서 UI를 재배치·장식할 때 **GDScript를 고치지 않아도 되게** 하는 규칙과, 그 규칙이 깨졌는지 확인하는 테스트를 정리한다.

게임 규칙(점수·주사위·라운드·상점 가격)은 이 문서의 범위가 아니다.

---

## 1. 기존 구조와 발견한 문제

### UI 씬

| 씬 | 루트 | 스크립트 |
|---|---|---|
| `scenes/game/main.tscn` | `Main` (Control) | `scripts/ui/main.gd` |
| `scenes/game/run_scene.tscn` | `RunScene` (Control) | `scripts/ui/run_scene.gd` |
| `scenes/game/shop_scene.tscn` | `ShopScene` (Control) | `scripts/ui/shop_scene.gd` |
| `scenes/ui/dice_slot.tscn` | `DiceSlot` (PanelContainer) | `scripts/ui/dice_slot.gd` |
| `scenes/ui/roll_lever.tscn` | `RollLever` (Control) | `scripts/ui/roll_lever.gd` |
| `scenes/dice/dice.tscn` | `Dice` (Control) | `scripts/dice/dice.gd` |

### 노드 참조는 이미 안전했다

조사 결과 UI 코드에 `$Path`, `get_node("A/B/C")`, `find_child()`가 **한 건도 없었다.** 모든 참조가 이미 `%UniqueName`이므로 계층 변경에 강했다. 따라서 경로 → Unique Name 치환 작업은 필요 없었다.

씬 간 연결도 `GameFlow` 시그널 + `preload`로 런타임 교체하는 구조라, 인스펙터 `@export` 참조를 끼울 자리가 없다. 억지로 `@export var hud`를 넣지 않았다.

### 실제 장애물 4가지

| # | 문제 | 증상 |
|---|------|------|
| 1 | 코드가 `custom_minimum_size`·StyleBox를 런타임에 덮어씀 | 에디터에서 지정한 Theme·색·크기가 실행하면 사라짐 |
| 2 | 코드가 컨테이너 자식을 `get_children()` 통째로 `queue_free` | 장식 노드·AnimationPlayer를 넣으면 첫 갱신에 삭제됨 |
| 3 | 반복 UI 4종이 `.tscn` 없이 코드로만 조립됨 | 에디터에서 열 방법이 없음 |
| 4 | 목표 구간·보상 골드 계산이 `run_scene.gd`(UI)에 있음 | UI를 고치려다 게임 규칙을 건드리게 됨 |

---

## 2. 적용한 규칙

### 규칙 A — 기본 스타일은 씬이, 상태 스타일만 코드가

상태에 따라 색이 바뀌는 컨트롤(`DiceSlot`, `ShopPoolCell`, `ShopOfferDie`)은 다음을 따른다.

1. **기본 상태의 StyleBox는 `.tscn`의 `theme_override_styles/panel`에 둔다.**
2. `_ready()`에서 오버라이드를 걸기 **전에** `get_theme_stylebox("panel")`을 캐시한다.
3. 기본 상태에서는 `remove_theme_stylebox_override("panel")` — 씬·Theme 값이 그대로 보인다.
4. 선택·드롭·잠금 등 상태에서는 캐시본을 `duplicate()`해서 **색과 테두리 두께만** 바꾼다.

결과: 에디터에서 모서리 반경·여백·폰트를 바꾸면 하이라이트 상태에서도 유지된다.

```gdscript
func _apply_style() -> void:
    var accent := _build_accent_style()
    if accent == null:
        remove_theme_stylebox_override("panel")
        return
    add_theme_stylebox_override("panel", accent)
```

### 규칙 B — 최소 크기는 씬이 우선

```gdscript
if custom_minimum_size == Vector2.ZERO:
    custom_minimum_size = SLOT_SIZE
```

씬에 값이 있으면 코드가 건드리지 않는다.

### 규칙 C — 코드는 자기가 만든 노드만 지운다

`get_children()`을 순회하며 전부 지우지 않는다. 생성한 노드를 배열에 담아두고 그것만 `queue_free()` 한다.

적용 위치: `main.gd`(`%UI`), `run_scene.gd`(`%BoardGrid`, `%RosterTray`), `score_phase_presenter.gd`(`%ScoreOverlay`), `active_hands_presenter.gd`(`%ActiveHandsList`), `dice_shop_presenter.gd`(`%ShopDiceRow`, `%PoolGrid`).

결과: 위 컨테이너 안에 배경 이미지·장식 노드·AnimationPlayer를 넣어도 살아남는다.

### 규칙 D — 커스텀 그리기 컨트롤은 색·치수를 `@export`로

`RollLever`는 전부 `_draw()`라 Theme가 먹지 않는다. 색·트랙 두께·노브 반지름·폰트 크기를 `@export`로 노출해 인스펙터에서 조정하게 했다. (`@tool`이 아니므로 에디터 미리보기는 되지 않는다. 값을 바꾸고 실행해서 확인한다.)

### 규칙 E — 반복 UI는 `.tscn`으로

| 새 씬 | 역할 | 인스턴스화 |
|---|---|---|
| `scenes/ui/shop_offer_die.tscn` | 상점 판매 주사위 카드 | `dice_shop_presenter.gd` |
| `scenes/ui/shop_pool_cell.tscn` | 보유 칸 (8개) | `dice_shop_presenter.gd` |
| `scenes/ui/active_hand_row.tscn` | 히스토리 한 줄 | `active_hands_presenter.gd` |
| `scenes/ui/face_preview_tooltip.tscn` | 주사위 면 호버 툴팁 | `face_preview_presenter.gd` |

"이번 층 기록 없음" 안내는 매번 만들지 않고 `run_scene.tscn`의 `%ActiveHandsEmptyHint` 노드를 `visible`로 껐다 켠다.

툴팁 크기 계산은 `get_theme_constant("separation")`으로 씬 값을 읽으므로, 에디터에서 간격을 바꾸면 계산도 따라간다.

### 규칙 F — 규칙 계산은 `scripts/core/`에

목표 점수를 배수로 넘길 때 생기는 구간과 보상 골드 액수를 `run_scene.gd`에서 `gold_calculator.gd`로 옮겼다.

| 함수 | 역할 |
|---|---|
| `GoldCalculator.build_threshold_segments(score, target)` | 0점부터 현재 점수까지의 구간 목록 |
| `GoldCalculator.find_threshold_segment(score, target)` | 지금 속한 구간 하나 |
| `GoldCalculator.threshold_step_reward(index)` | index번째 임계를 넘길 때 받는 골드 |

`run_scene.gd`에는 tween·진행 바 색·"+N 골드" 띄우기만 남았다. `threshold_step_reward`의 누적이 `calculate_reward`와 일치하는지 스펙 테스트가 검사한다.

---

## 3. 사람이 UI를 수정하는 방법

| UI 씬 | 자유롭게 수정 가능 | 이름을 유지할 핵심 노드 | 연결 방식 |
|---|---|---|---|
| `main.tscn` | `%UI` 밖의 배경·오버레이 추가 | `UI` | `%UniqueName` |
| `run_scene.tscn` | 위치, 크기, Panel·Container 추가, Anchor, Theme, 폰트, 색, 장식 노드, AnimationPlayer | `FloorLabel` `GoldLabel` `TargetScoreLabel` `CurrentScoreLabel` `TargetProgressBar` `ProgressValueLabel` `StatusLabel` `DiceRow` `BoardGrid` `RosterTray` `ScoreOverlay` `PopupOverlay` `LeftValue` `RightValue` `RollLever` `NextFloorButton` `ActiveHandsList` `ActiveHandsEmptyHint` `RoundController` `RollPhasePresenter` `ScorePhasePresenter` `FacePreviewPresenter` `ActiveHandsPresenter` | `%UniqueName` |
| `shop_scene.tscn` | 위와 같음 | `FloorLabel` `GoldLabel` `StatusLabel` `ShopDiceRow` `PoolGrid` `PendingLabel` `ConfirmButton` `ContinueButton` `PopupOverlay` `DiceShopPresenter` `FacePreviewPresenter` | `%UniqueName` |
| `dice_slot.tscn` | 크기, StyleBox, 장식 | `DiceHolder` | `%UniqueName` |
| `shop_offer_die.tscn` | 크기, StyleBox, 장식 | `DiceHolder` | `%UniqueName` |
| `shop_pool_cell.tscn` | 크기, StyleBox, 장식 | `DiceHolder` | `%UniqueName` |
| `active_hand_row.tscn` | 폰트, 색, 간격, 아이콘 추가 | `HandLabel` `ScoreLabel` | `%UniqueName` |
| `face_preview_tooltip.tscn` | StyleBox, 간격 | `Content` `FacesRow` `DescBox` | `%UniqueName` |
| `roll_lever.tscn` | 인스펙터의 Appearance · Layout 값 | (자식 없음) | `@export` |

### UI 편집 시 규칙

- 위 표의 **핵심 노드 이름은 유지**한다. 이름을 바꾸면 코드가 찾지 못한다.
- 핵심 노드를 **삭제하지 말고 이동하거나 꾸민다.** 다른 Panel·Container 아래로 옮기는 것은 자유다.
- Panel과 Container는 자유롭게 추가할 수 있다. 중간에 몇 겹이 끼어도 `%UniqueName`은 그대로 찾는다.
- 장식용 노드는 자유롭게 추가·삭제·리네임할 수 있다.
- 핵심 노드의 **타입**을 바꿀 때는 연결 코드를 확인한다 (`Label` → `RichTextLabel` 등).
- 노드를 지우고 새로 만들면 **Access as Unique Name을 다시 켠다.**
- 노드를 **하위 씬 인스턴스 안으로** 옮기면 owner가 바뀌어 `%UniqueName`이 끊긴다. 같은 씬 안에서만 옮긴다.

### 코드가 관리하는 컨테이너

아래 컨테이너의 **자식 목록은 코드가 채운다.** 장식 노드를 넣어도 지워지지는 않지만, 자식 순서·개수는 실행 중 바뀐다.

`%UI` · `%BoardGrid` · `%RosterTray` · `%ScoreOverlay` · `%PopupOverlay` · `%ActiveHandsList` · `%ShopDiceRow` · `%PoolGrid`

`%BoardGrid`의 `columns`는 `RunManager.BOARD_COLS`, `%PoolGrid`의 `columns`는 `DiceShopPresenter.POOL_COLS`가 실행 시 덮어쓴다. 열 수는 에디터에서 바꿔도 반영되지 않는다.

---

## 4. 검증

`ui_scene_spec_test.gd`가 `.tscn` 텍스트를 읽어 위 표의 핵심 노드가 `unique_name_in_owner = true`로 남아 있는지 확인한다. 이름을 바꾸거나 Unique Name을 끄면 실패한다.

```bash
..\Godot_v4.7-stable_mono_win64_console.exe --headless --path . \
  --log-file .godot/agent-headless.log \
  --script res://scripts/core/ui_scene_spec_test.gd
```

씬을 `load()`하지 않고 텍스트를 파싱한다. `--script` 모드에는 Autoload가 없어 `RunManager`를 참조하는 스크립트의 컴파일이 실패하기 때문이다.

씬이 실제로 뜨는지는 부팅으로 확인한다.

```bash
..\Godot_v4.7-stable_mono_win64_console.exe --headless --path . \
  --log-file .godot/agent-headless.log --quit-after 30 \
  res://scenes/game/shop_scene.tscn
```

---

## 관련 스펙

- [scene-run-lifecycle.md](scene-run-lifecycle.md) — 씬 전환·런·라운드 흐름
- [gold-economy.md](gold-economy.md) — `GoldCalculator`의 골드 공식
- [script-preloads.md](script-preloads.md) — `preload` 경로 명시 규칙

## 남은 문제 (칸반 `ideas`)

이 피쳐에서 일부러 남긴 잔여. 카드: `run-scene-hud-split` · `sidebar-layout-coupling` · `run-scene-overlay-rename` · `ui-dead-code-cleanup` · `roll-lever-tool-preview`. 요약은 [docs/backlog.md](../../backlog.md) 「UI 편집·잔여」.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-26 | 남은 문제 → 칸반 ideas 5장 · 백로그 링크 |
| 2026-07-26 | UI 편집 규칙 A~F 정리 · 반복 UI 4종 씬 분리 · 핵심 노드 이름 테스트 추가 |
