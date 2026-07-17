# Task: 주사위 로스터·상점

## Task 1. 스펙·인덱스

**목적:** 보유 주사위·상점 규칙 정본

**수정 예상 파일:**
- `docs/design/systems/dice-roster-shop.md`
- `docs/design/systems/README.md`
- `docs/design/v0.1-initial-playable.md` §6 한 줄

**수정 금지:**
- `hand-scoring-v2.md` 족보·점수 공식 본문
- 리롤 비용·횟수

**완료 조건:**
- AC·플로우·MVP 오퍼(H 교체) 문서화

---

## Task 2. DiceRoster + RunManager

**목적:** 시작 4기본, 교체 API

**수정 예상 파일:**
- `scripts/core/dice_roster.gd`
- `scripts/autoload/run_manager.gd`
- `scripts/core/dice_roster_spec_test.gd`

**수정 금지:**
- `hand_calculator.gd`

**완료 조건:**
- `reset_to_starting()` → 4× basic_d6
- `replace_with_h_at(i)` 동작
- headless 스펙 테스트 통과

---

## Task 3. RoundController·run_scene 연동

**목적:** 로스터 → `dice_resources`, 동적 슬롯 수

**수정 예상 파일:**
- `scripts/ui/run_scene.gd`
- `scenes/game/run_scene.tscn`

**수정 금지:**
- `score_phase_presenter.gd` 연출 규칙

**완료 조건:**
- 첫 라운드 4주사위 UI
- 층 전환 후 로스터 반영·`_spawn_dice` 재구성

---

## Task 4. 상점 UI

**목적:** Next Floor → 상점 → H 교체 → 다음 층

**수정 예상 파일:**
- `scripts/ui/dice_shop_presenter.gd`
- `scenes/game/run_scene.tscn`
- `scripts/ui/run_scene.gd`

**완료 조건:**
- AC 상점 플로우·교체·다음 층 수동 검증 가능
