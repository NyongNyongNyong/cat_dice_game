# 주사위 로스터·상점 (보유 주사위)

> **문서 유형:** 시스템 스펙  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §3·§4.1 — 런 동안 주사위 수집·성장  
> **카탈로그:** [dice-catalog.md](dice-catalog.md) — `dice_defs.json`, id 기반 보유·교체  
> **면·리소스:** [dice-resources.md](dice-resources.md) — `DiceResource`  
> **상태:** v0.1 골격 (교체 1종만)  
> **구현:** `dice_roster.gd` · `run_manager.gd` · `dice_shop_presenter.gd` · `run_scene.gd`

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

- `REROLL_READY` + `RunManager.can_advance_floor()` (목표 점수 달성).
- **Next Floor** 클릭 → 상점 패널 표시 (즉시 층 이동하지 않음).

### 상점 (MVP)

| 오퍼 | 동작 |
|------|------|
| **오퍼 교체** | 슬롯 `i`를 카탈로그 id `dice_triple_h` (H,H,H,1,1,1)로 교체 |
| **다음 층** | 상점 닫기 → `advance_floor()` → 로스터 반영 → 새 라운드 |

- 성장·추가 오퍼: **미구현** (UI·API 자리만 확장 가능).
- 교체는 슬롯당 여러 번 가능 (이미 H여도 동일 리소스로 재설정 가능).

### 다음 층

- 상점 **다음 층** 후 `begin_round()` — 변경된 로스터로 주사위 UI 재구성.

---

## 표시 정보

| 위치 | 내용 |
|------|------|
| 상점 제목 | `상점` |
| 슬롯 행 | `슬롯 N · {display_name}` — 어두운 글자색 (`#2E2620` 계열), 밝은 패널 배경 대비 |
| 교체 버튼 | `교체` (오퍼 이름은 상단 패널에 표시) |
| 진행 버튼 | `다음 층` |
| 상태 문구 | 상점 중: `상점에서 주사위를 교체한 뒤 다음 층으로 이동하세요.` |

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
| 상점 표시 중 | Roll·리롤·Preview 비활성 |
| 빈 로스터 | `start_run`이 항상 4개로 초기화 — 발생하지 않음 |

---

## 영향받는 시스템

| 시스템 | 변경 |
|--------|------|
| `RunManager` | `DiceRoster` 보유, `roster_changed` |
| `RoundController` | `dice_resources` ← 로스터 |
| `run_scene` | 상점 플로우, `_spawn_dice()` 개수 동적 |
| `hand-scoring-v2` | **미변경** (족보·공식) |
| `dice-hover-reroll-preview` | **미변경** (슬롯별 리소스 이미 지원) |

---

## Acceptance Criteria

- [ ] 런 시작 시 기본 주사위 **4개**만 굴린다.
- [ ] 목표 달성 후 Next Floor → **상점**이 열린다.
- [x] 상점에서 슬롯별 **카탈로그 id 교체**(`dice_triple_h`)가 로스터에 반영된다.
- [ ] 다음 층 시작 시 교체된 주사위로 굴림·점수·H 면 표시가 동작한다.
- [ ] 성장·추가는 UI/코드에 오퍼 확장 지점만 있고 동작은 없다.

---

## 구현 메모

| 항목 | 경로 |
|------|------|
| 로스터 | `game/scripts/core/dice_roster.gd` |
| 상점 UI | `game/scripts/ui/dice_shop_presenter.gd` |
| 카탈로그 | `game/data/dice/dice_defs.json` · `dice_catalog_service.gd` |
| 테스트 | `game/scripts/core/dice_roster_spec_test.gd` |

`RunManager.DICE_COUNT`(10)는 레거시 fallback; 로스터가 있으면 `dice_resources.size()` 우선.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | 슬롯 행 동적 라벨 글자색·크기 — 밝은 배경에서 가독성 |
| 2026-06-09 | 상점 UI — 오퍼 패널·슬롯 행·교체 버튼 레이아웃 |
| 2026-06-09 | 카탈로그 id 교체 — `dice_triple_h`, H 전용 API 제거 |
| 2026-06-08 | 초안 — 보유 로스터·상점 골격, H 교체 MVP |
