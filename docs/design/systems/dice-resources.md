# 주사위 리소스·면(Face) 시스템

> **문서 유형:** 시스템 스펙 (데이터·해석·UI 연동)  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §5 — 면은 **눈금·문양** 표기, 숫자 텍스트가 아님  
> **점수 입력:** 해석된 `dice_values` → [hand-scoring-v2.md](hand-scoring-v2.md) `HandCalculator`  
> **면 UI 표시:** [hand-scoring-v2.md](hand-scoring-v2.md) §13.4 — pip·문양만, 아라비아 숫자 금지  
> **리롤 Preview:** [dice-hover-reroll-preview.md](dice-hover-reroll-preview.md) — `compute_from_faces`  
> **상태:** v0.1 구현 완료 (TwoEG `feature/dice-resources`, `feature/reroll-face-properties`)  
> **구현:** `dice_resource.gd` · `dice_face.gd` · `number_face.gd` · `special_face.gd` · `face_properties/` · `round_controller.gd` · `dice.gd`

---

## 1. 목적

주사위를 **리소스(`DiceResource`)** 로 정의하고, 각 면을 **`DiceFace` 서브리소스**로 표현한다.

| 계층 | 역할 |
|------|------|
| **면 리소스** | 굴림 결과·화면 표시·(선택) 점수 해석 규칙 |
| **해석 값** | 보드 전체 맥락으로 `resolve_number_value` → `dice_values[i]` |
| **점수** | `HandCalculator.evaluate(dice_values)` — 면 구조와 분리 |

플레이어가 보는 것은 **굴린 면**(눈금·문양). 점수에 쓰이는 숫자는 내부 해석 결과이며, 주사위 UI에 숫자 텍스트로 노출하지 않는다 (§6).

---

## 2. 리소스 모델

### 2.1 `DiceResource`

| 필드 | 설명 |
|------|------|
| `id` | 식별자 (`&"dice_basic"` 등) |
| `display_name` | 에디터·UI 메타 (주사위 면에 그리지 않음) |
| `faces` | `DiceFace` 서브리소스 배열 — **실제 면 목록** |
| `face_values` | `faces`가 비었을 때만 사용하는 **fallback** 숫자 목록 (런타임 `NumberFace` 생성) |

| API | 동작 |
|-----|------|
| `get_faces()` | `faces` 비어 있으면 `face_values`로 `NumberFace` 동적 생성 |
| `roll_face()` | `get_faces()` 중 균등 랜덤 1개 |
| `resolve_face_value(face, context_faces)` | 보드 맥락으로 면 1개 → 정수 |
| `resolve_face_values(context_faces)` | 보드 전체 → `Array[int]` |
| `get_roster_preview_face()` | **굴리기 전** 슬롯 표시용 면 — 특수면 1개 있으면 그중 첫 특수면, 없으면 **최고 pip** `NumberFace` |
| `get_roster_preview_value(context_faces?)` | 위 면을 `resolve_face_value`로 해석한 값 (컨텍스트 없으면 `get_faces()` 사용) |

**카탈로그 정본:** [dice-catalog.md](dice-catalog.md) — `game/data/dice/dice_defs.json` (v2, 면 6개 필수).  
**레거시 fallback:** `game/resources/dice/basic_d6.tres` — `RoundController` 기본 리소스·에디터 참고용.

### 2.2 `DiceLoadoutResource`

슬롯별로 다른 `DiceResource`를 쓸 때 사용.

| 필드 | 설명 |
|------|------|
| `dice` | 슬롯 순서대로 `DiceResource` 배열 |

`RoundController.get_dice_resource(index)` 우선순위: **loadout 슬롯** → `dice_resources[index]` → `default_dice_resource` → `basic_d6.tres`.

### 2.3 카탈로그 주사위 예

| id | 면 | 비고 |
|----|-----|------|
| `dice_basic` | 1,2,3,4,5,6 | 시작·기본 |
| `dice_triple_h` | H,H,H,1,1,1 | 상점 오퍼 MVP |

레거시 `.tres` (`change_to_highest_test.tres` 등)는 회귀·에디터 참고용; 신규 주사위는 JSON 카탈로그에 추가.

---

## 3. 면(Face) 타입

공통 기반: `DiceFace` (`dice_face.gd`)

| 메서드 | 용도 |
|--------|------|
| `is_number()` | 숫자 면 여부 (`NumberFace`만 `true`) |
| `get_base_number_value()` | 속성 적용 **전** 기본 숫자 |
| `resolve_number_value(context)` | `properties` 체인 적용 후 **점수용** 정수 |
| `get_display_text(context)` | 주사위 UI용 문자열 (숫자 면은 비움) |
| `has_visual_effect()` / `play_visual_effect()` | 굴림 후 연출 (선택) |

### 3.1 `NumberFace`

| 필드 | 설명 |
|------|------|
| `value` | 면 고유 값 (1~6 등) — **pip 개수**와 점수 기본값 |

- `get_display_text()` → 항상 `""` → `dice.gd`가 **pip 레이아웃**만 그림.
- `display_name`은 에디터용; 주사위에 숫자 문자열로 쓰지 않는다.

### 3.2 `SpecialFace`

| 필드 | 설명 |
|------|------|
| `symbol_id` | 문양 ID (속성이 표시 텍스트를 안 줄 때 fallback) |
| `properties` | `FaceProperty` 서브리소스 — 해석·표시·연출 |

- `get_display_text()` — `properties` 우선, 없으면 `str(symbol_id)`.
- `display_name`(예: `"Change To Highest"`)은 **에디터 메타**, 주사위 면에 긴 이름을 그리지 않음.

---

## 4. `FaceProperty` (면 속성)

기반: `face_property.gd` — 서브클래스가 필요 메서드만 override.

| 훅 | 시그니처 요약 | 용도 |
|----|----------------|------|
| `resolve_number_value` | `(face, context, current) → int` | 점수 해석 (보드 맥락) |
| `get_display_text` | `(face, context, current_text) → String` | 면 문양 텍스트 |
| `has_visual_effect` | `() → bool` | 굴림 후 연출 여부 |
| `play_visual_effect` | `(dice_view, face, context) → await` | 회전 등 UI 연출 |

`context` 예시 (`play_visual_effect`):

```gdscript
{"faces": faces, "resolved_value": values[i], "dice_index": i}
```

### 4.1 `ChangeToHighestProperty` (구현 예)

| 항목 | 동작 |
|------|------|
| `resolve_number_value` | 같은 보드의 다른 `NumberFace` 중 **최대 `value`**, 최소 1 |
| `get_display_text` | `"H"` |
| `play_visual_effect` | 360° 회전 트윈 (면 표시는 `set_face` 유지, `set_value`로 덮지 않음) |

**예:** 보드 `[3, 5, H]` — H 면 해석값 = 5 (다른 숫자 면 최대).

---

## 5. 해석 파이프라인

```text
_roll_die_face(i) → Resource (굴린 면)
        ↓
dice_faces[0..9]  (보드 면 배열)
        ↓
resolve_faces(dice_faces) → dice_values[0..9]
        ↓
HandCalculator.evaluate(dice_values)
```

- `resolve_face_value(face, context_faces)`는 **항상 전체 보드** `context_faces`를 넘긴다.  
  속성이 “다른 주사위 면”을 참조할 수 있게 하기 위함 (`ChangeToHighest`).
- `DiceResource.resolve_face_value`가 `face.resolve_number_value({"faces": context_faces})` 호출.

---

## 6. UI 표시 (`dice.gd`)

**정본:** [hand-scoring-v2.md](hand-scoring-v2.md) §13.4

| API | 용도 |
|-----|------|
| `set_face(face, resolved_value)` | **유일한** 면 표시 진입점 |
| `show_placeholder()` | 빈 슬롯 |

| `face` 종류 | 그리기 |
|-------------|--------|
| `NumberFace` | `value` 기준 **pip** (`PIP_LAYOUTS`) |
| `SpecialFace` | `get_display_text()` **문양 텍스트** (`H` 등) |

- `resolved_value`는 점수·속성 해석용; **숫자 면 pip 개수에는 쓰지 않음** (굴린 면 `value`만).
- `set_value` API **없음** (숫자 텍스트·해석값 직접 표시 금지).

**연동:** `run_scene.gd` — 굴림·리롤 후 `set_face(faces[i], values[i])`.  
`score_phase_presenter.gd` — 연출·포커스 클론도 동일.

---

## 7. `RoundController` 연동

| 상태 | 내용 |
|------|------|
| `dice_faces` | 현재 보드 면 리소스 10개 |
| `dice_values` | `resolve_faces(dice_faces)` 캐시 |
| `get_reroll_preview(i)` | 해당 슬롯 `DiceResource.get_faces()` 후보로 `compute_from_faces` |
| `get_reroll_face_values(i)` | 후보별 **맥락 해석** 정수 (레거시/디버그용) |

슬롯마다 다른 `DiceResource` 가능 (loadout / per-slot 배열).

---

## 8. 리롤 Preview 연동

[dice-hover-reroll-preview.md](dice-hover-reroll-preview.md) §4와 동일 로직이며, 입력이 **면 후보**로 확장됨.

```text
compute_from_faces(dice_faces, dice_index, candidate_faces)
  → 각 candidate로 trial_faces 구성
  → resolve → HandCalculator.evaluate
  → delta_up / delta_down
```

`[1,2,3,4,5,6]` 고정 루프(`compute(dice_values, …, face_values)`)는 **fallback**;  
현재 `RoundController.get_reroll_preview`는 **리소스 면 목록** 경로를 사용한다.

---

## 9. 구현·테스트

| 항목 | 경로 |
|------|------|
| 계산·해석 | `game/scripts/core/dice_resource.gd` |
| 면 타입 | `number_face.gd`, `special_face.gd`, `dice_face.gd` |
| 속성 | `game/scripts/core/face_properties/` |
| 라운드 | `round_controller.gd` |
| 뷰 | `game/scripts/dice/dice.gd`, `run_scene.gd` |
| Preview | `reroll_preview_calculator.gd` — `compute_from_faces` |
| 회귀 테스트 | `dice_resource_spec_test.gd` — 해석·loadout·change-to-highest·number face display |

---

## 10. v0.1 범위·미구현

| 포함 | 미포함 (추후) |
|------|----------------|
| `DiceResource` / `NumberFace` / `SpecialFace` | GDD §5 문양 종류·폭탄 등 콘텐츠 대량 |
| `FaceProperty` 확장 포인트 | 카지노 규칙·유물이 면 해석에 개입 |
| 슬롯별 loadout API | [dice-roster-shop.md](dice-roster-shop.md) — 보유 로스터·상점 (시작 4기본) |
| `basic_d6` 기본 10슬롯 | 런 로스터가 슬롯 수 결정 (레거시 `DICE_COUNT`는 fallback) |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | `get_roster_preview_face()` / `get_roster_preview_value()` — 굴림 전 슬롯 표시 |
| 2026-06-09 | 카탈로그 정본 링크 (`dice-catalog.md`), `dice_triple_h` 6면 |
| 2026-06-08 | §10 — 보유 로스터·상점 링크 (`dice-roster-shop.md`) |
| 2026-06-08 | 초안 — TwoEG `dice-resources`·`reroll-face-properties` 구현 정본, UI §13.4 교차 참조 |
