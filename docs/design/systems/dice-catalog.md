# 주사위 카탈로그 (Dice Catalog)

> **문서 유형:** 시스템 스펙  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §4 — 주사위 수집·편성  
> **면·런타임:** [dice-resources.md](dice-resources.md) — `DiceResource` / `NumberFace` / `SpecialFace`  
> **로스터·상점:** [dice-roster-shop.md](dice-roster-shop.md)  
> **상태:** v1 구현  
> **구현:** `dice_catalog_service.gd` · `dice_catalog.gd` (Autoload) · `game/data/dice/dice_defs.json` · `starter_loadout.json`

---

## 목적

기본·특수 주사위를 **별도 코드 경로 없이** 단일 카탈로그에서 정의한다.

| 원칙 | 설명 |
|------|------|
| **카탈로그** | 모든 주사위 종류 + **6면** 정의 (`dice_defs.json`) |
| **보유** | 런마다 `dice_id` 배열 (`starter_loadout.json` → 이후 상점·보상) |
| **런타임** | id → `DiceResource` (공유 템플릿). 굴림은 6면 중 균등 1면 |
| **확장** | 새 주사위 = JSON 항목 추가 + (필요 시) `property_id` 핸들러 |

`basic_d6.tres` 등 개별 `.tres`는 **fallback·테스트**용으로만 유지한다. 정본 데이터는 JSON.

---

## 동작 조건

### 카탈로그 로드

- 게임 시작 시 Autoload `DiceCatalog`가 `registry.json` → `dice/dice_defs.json` 로드.
- 각 항목을 `DiceResource`로 빌드해 `id`별 캐시.
- **면 6개 필수** — 미만/초과 시 해당 주사위 로드 실패(에러 로그), 스킵.

### 보유 로스터

- `DiceRoster.reset_to_starting()` → `starter_loadout.json`의 `owned_dice_ids` 순서대로 슬롯 채움.
- 슬롯 `i`는 카탈로그의 `DiceResource` **참조**(동일 id는 동일 템플릿 공유).

### 상점 교체 (MVP)

- 오퍼 id: `dice_triple_h` (고정 상수, 추후 `shop_pools.json` 연동).
- `replace_at_index(slot, dice_id)` — H 전용 API 제거.

### 굴림

- 변경 없음: `DiceResource.roll_face()` → `faces` 중 1면.
- 숫자·특수 면 해석은 [dice-resources.md](dice-resources.md) 동일.

---

## 데이터 형식 (`dice_defs.json` v2)

```json
{
  "id": "dice_basic",
  "display_ko": "기본 주사위",
  "display_name": "Basic Die",
  "faces": [
    { "kind": "number", "value": 1 },
    { "kind": "special", "property_id": "change_to_highest" }
  ]
}
```

| `kind` | 필드 | 런타임 |
|--------|------|--------|
| `number` | `value` (1~6 등) | `NumberFace` |
| `special` | `property_id` | `SpecialFace` + 등록된 `FaceProperty` |

### 등록 주사위 (v1)

| id | 면 구성 | 비고 |
|----|---------|------|
| `dice_basic` | 1,2,3,4,5,6 | 기본 |
| `dice_triple_h` | H,H,H,1,1,1 | `change_to_highest` |
| `dice_bomb` | 1,2,3 + bomb×3 | bomb 효과 **미구현** — 숫자 면 placeholder (추후) |
| `dice_golden` | 2,2,3,3,4,4 | 효과 미구현 — 숫자만 |

`dice_bomb` / `dice_golden`은 카탈로그에만 존재; 상점·시작 로드아웃에는 미사용.

---

## 표시 정보

| 위치 | 내용 |
|------|------|
| 상점 슬롯 | `슬롯 N: {display_ko 또는 display_name}` |
| 교체 버튼 | `{display_ko}로 교체` (오퍼 id 기준) |

---

## 예외 조건

| 상황 | 동작 |
|------|------|
| 알 수 없는 `dice_id` | 교체·로드 실패, 로스터 변경 없음 |
| 카탈로그 로드 실패 | `dice_basic` 4개 fallback |
| `property_id` 미등록 | 해당 면 로드 실패 → 주사위 전체 스킵 |

---

## 영향받는 시스템

- `DiceCatalog` (Autoload) — 신규
- `dice_roster.gd` — id 기반, H 하드코딩 제거
- `run_manager.gd` — `replace_owned_dice_at(slot, dice_id)`
- `dice_shop_presenter.gd` — 오퍼 id 기반 버튼 문구
- `dice-resources.md` · `dice-roster-shop.md` — 카탈로그 참조 갱신

**수정 금지:** `hand_calculator.gd`, 족보 규칙, 점수 공식.

---

## Acceptance Criteria

- [x] `dice_defs.json`에 기본·`dice_triple_h`(H×3, 1×3)가 **각 6면**으로 정의된다.
- [x] `DiceCatalogService`가 id로 `DiceResource`를 반환한다.
- [x] 런 시작 시 `starter_loadout.json` id 목록으로 로스터가 채워진다.
- [x] 상점 교체가 `dice_id` 기반이며 H 전용 API가 없다.
- [x] `dice_triple_h` 굴림·해석·H 표시·리롤 Preview가 6면 기준으로 동작한다.
- [x] `dice_catalog_spec_test` · `dice_roster_spec_test` 통과.

---

## 구현 메모

| 항목 | 경로 |
|------|------|
| 카탈로그 | `game/scripts/autoload/dice_catalog.gd` |
| 데이터 | `game/data/dice/dice_defs.json`, `starter_loadout.json` |
| property 맵 | `change_to_highest` → `change_to_highest_property.gd` |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | v1 — JSON 카탈로그·Autoload·로스터/상점 id 통합 |
