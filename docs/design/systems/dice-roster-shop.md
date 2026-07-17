# 주사위 로스터·상점 (보유 주사위)

> **문서 유형:** 시스템 스펙  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §3·§4.1 — 런 동안 주사위 수집·성장  
> **카탈로그:** [dice-catalog.md](dice-catalog.md) — `dice_defs.json`, id 기반 보유·교체  
> **면·리소스:** [dice-resources.md](dice-resources.md) — `DiceResource`  
> **상태:** v0.1 골격 (교체 1종만)  
> **구현:** `dice_roster.gd` · `run_manager.gd` · `dice_shop_presenter.gd` · `shop_scene.tscn` · `game_flow.gd`

---

## 목적

주사위를 **풀에서 뽑는 방식이 아니라**, 런 시작 시 보유 목록을 갖고 **성장·교체·추가**로 관리한다.

| 원칙 | 설명 |
|------|------|
| 보유 목록 | `DiceRoster` — 슬롯별 `DiceResource` 참조 |
| 라운드 입력 | `RoundController.dice_resources` ← 로스터 스냅샷 |
| 상점 타이밍 | 층 목표 달성 후 **다음 층 전** 1회 |
| 확장 | 교체·추가·성장 액션을 상점 오퍼로 플러그인 (이번: 교체만) |

---

## 동작 조건

### 시작

- 런 `start_run()` 시 `starter_loadout.json` id 목록으로 로스터 초기화 (v1: `dice_basic` × 4).
- 주사위 개수 = 로스터 `size` (고정 10 아님).

### 라운드

- 굴림·리롤·점수·족보는 기존과 동일. 슬롯 수만 로스터 길이를 따른다.

### 상점 진입

- `READY` + `RunManager.can_advance_floor()` (목표 점수 달성).
- **Next Floor** 클릭 → **상점 씬**으로 전환 (`GameFlow.show_shop()`). 즉시 층 이동하지 않음.

### 상점 (v0.2 — 드래그 & 대기 구매)

3단 레이아웃 (위 → 아래):

1. **아이템 행** — `아이템 A/B/C` 플레이스홀더. 아이템 종류 미정(GDD §11)이라 표시만, 상호작용 없음.
2. **상점 주사위 행** — `shop_offers.json`의 등장 주사위. 각 카드를 **드래그**해서 아래 보유 칸으로 옮긴다.
3. **보유 풀** — 4×2 = **8칸**(`MAX_OWNED_DICE`). 슬롯 번호 라벨 없음.

- **동선:** 상점 주사위를 보유 칸으로 **드래그&드롭** → 대기 구매 표시(초록 칸) → **확인**으로 확정.
- **가격:** 주사위당 고정 **3골드**(`RunManager.SHOP_DICE_PRICE`). 대기 총액 = 3 × 대기 개수.
- **빈 칸에 드롭** = 추가(add), **주사위 있는 칸에 드롭** = 교체(replace). 둘 다 개당 3골드.
- **대기 취소:** 대기 칸(초록)을 클릭하면 그 구매를 취소.
- **확인:** `purchase_dice_batch(entries)` — 총액을 골드에서 한 번에 차감하고 로스터에 반영. 골드 부족·용량 초과면 확인 비활성.
- **다음 층:** `advance_floor()` → RunScene 복귀. 남은 대기 구매는 버려진다.

### 다음 층

- 상점 **다음 층** 후 `begin_round()` — 변경된 로스터로 주사위 UI 재구성.

---

## 표시 정보

| 위치 | 내용 |
|------|------|
| 상점 씬 | [shop-scene.md](shop-scene.md) — Full Rect, ScrollContainer |
| 상점 제목 | `상점 · 층 N` |
| 아이템 행 | `아이템 A/B/C` 플레이스홀더 (미정) |
| 상점 주사위 행 | 드래그 가능한 주사위 카드 (미리보기 면) |
| 보유 풀 | 4×2 8칸 그리드 — 번호 없음, 대기 칸은 초록 |
| 진행 버튼 | `확인` (대기 확정) · `다음 층` |
| 대기 표시 | `구매 대기 N개 · M골드` (부족 시 빨강) |
| 상태 문구 | 드래그 안내 · 확인 안내 · 골드 부족 · 구매 완료 |

주사위 면 표시 규칙은 [hand-scoring-v2.md](hand-scoring-v2.md) §13.4 · [dice-resources.md](dice-resources.md) §6.

---

## 계산 방식

- 점수·족보·리롤 Preview: 변경 없음. `dice_faces` / `resolve_faces`는 로스터의 `DiceResource`를 그대로 사용.
- `dice_triple_h` 교체 후 Preview는 해당 슬롯 `get_faces()` **6면** 후보 기준.

---

## 예외 조건

| 상황 | 동작 |
|------|------|
| 목표 미달성 | 상점 진입 불가 (Next Floor 비활성) |
| 5층 클리어 후 | 상점 없음, 런 종료 |
| 상점 표시 중 | RunScene 언로드 — Roll·리롤 불가 |
| 빈 로스터 | `start_run`이 항상 4개로 초기화 — 발생하지 않음 |

---

## 영향받는 시스템

| 시스템 | 변경 |
|--------|------|
| `RunManager` | `DiceRoster` 보유, `roster_changed` |
| `RoundController` | `dice_resources` ← 로스터 |
| `run_scene` | Next Floor → `GameFlow.show_shop()` |
| `shop_scene` | 드래그&드롭 풀 UI·확인/다음 층 |
| `RunManager` | `add_owned_dice`, `purchase_dice_batch`, `SHOP_DICE_PRICE` |
| `dice_roster` | `add_dice(dice_id)` |
| `hand-scoring-v2` | **미변경** (족보·공식) |
| `dice-hover-reroll-preview` | **미변경** (슬롯별 리소스 이미 지원) |

---

## Acceptance Criteria

- [x] 목표 달성 후 Next Floor → **상점**이 열린다.
- [x] 상점 주사위를 보유 칸으로 드래그하면 대기 구매(초록 칸)로 표시된다.
- [x] 빈 칸=추가, 있는 칸=교체. 대기 칸 클릭 시 취소.
- [x] **확인**이 대기 총액(3골드/개)을 한 번에 차감하고 로스터에 반영한다.
- [x] 골드 부족·8칸 초과면 확인이 비활성된다. (`shop_purchase_spec_test`)
- [ ] 다음 층 시작 시 추가·교체된 주사위로 굴림·점수·특수 면 표시가 동작한다.

---

## 구현 메모

| 항목 | 경로 |
|------|------|
| 로스터 | `scripts/core/dice_roster.gd` (`add_dice`) |
| 상점 UI | `shop_scene.tscn` · `dice_shop_presenter.gd` |
| 드래그/드롭 | `shop_offer_die.gd` (소스) · `shop_pool_cell.gd` (대상) |
| 카탈로그 | `data/dice/dice_defs.json` · `dice_catalog_service.gd` |
| 테스트 | `dice_roster_spec_test.gd` · `shop_purchase_spec_test.gd` |

`RunManager.DICE_COUNT`(10)는 레거시 fallback; 로스터가 있으면 `dice_resources.size()` 우선.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-04 | 상점 v0.2 — 아이템/주사위/풀 3단, 드래그&드롭 대기 구매, 4×2 풀, 고정 3골드 |
| 2026-06-09 | 골드 구매·H/L/V 3종 — [shop-purchase.md](shop-purchase.md) |
| 2026-06-09 | 상점 독립 씬 — [shop-scene.md](shop-scene.md) |
| 2026-06-09 | 슬롯 행 동적 라벨 글자색·크기 — 밝은 배경에서 가독성 |
| 2026-06-09 | 상점 UI — 오퍼 패널·슬롯 행·교체 버튼 레이아웃 |
| 2026-06-09 | 카탈로그 id 교체 — `dice_triple_h`, H 전용 API 제거 |
| 2026-06-08 | 초안 — 보유 로스터·상점 골격, H 교체 MVP |
