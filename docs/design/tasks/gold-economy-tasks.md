# Task: 골드·칩 경제 (gold-economy)

## Task 1. GDD·시스템 스펙 정리

**목적:**
- 칩(점수) vs 골드(오버킬·소비) 방향을 GDD에 반영
- `gold-economy.md` 정본 작성·인덱스 등록

**수정 예상 파일:**
- `docs/gdd-cat-tower-casino.md`
- `docs/design/systems/gold-economy.md`
- `docs/design/systems/README.md`
- `data/economy/gold_reward.json`

**수정 금지:**
- 족보·점수 공식 본문

**완료 조건:**
- GDD §10이 칩/골드 이원화를 설명
- AC·공식 예시가 스펙에 기록됨

---

## Task 2. 골드 계산기·단위 테스트

**목적:**
- 골드 획득 공식 v2 구현 및 예시 검증

**수정 예상 파일:**
- `scripts/core/gold_calculator.gd`
- `scripts/core/gold_calculator_spec_test.gd`

**수정 금지:**
- `hand_calculator.gd`, `hand-scoring-v2.md`

**완료 조건:**
- `T=5`, `r=2` 예시 표 전 행 통과
- `S < T` → 0

---

## Task 3. RunManager 골드 상태

**목적:**
- 골드 잔액·시그널·라운드 정산·리롤 차감 API

**수정 예상 파일:**
- `scripts/autoload/run_manager.gd`

**수정 금지:**
- 족보 계산, `FLOOR_TARGETS` 밸런스 임의 변경

**완료 조건:**
- `start_run` 시 gold=0
- `collect_round_gold()`가 공식대로 지급
- `try_spend_reroll_gold()` 성공/실패 분기

---

## Task 4. 리롤 골드 비용

**목적:**
- 목표 달성 후 리롤 1골드 차감·부족 시 차단

**수정 예상 파일:**
- `scripts/core/round_controller.gd`

**수정 금지:**
- 리롤 Preview 계산, 족보 규칙

**완료 조건:**
- 미달 시 무료 리롤 유지
- 달성 후 골드 부족 시 `can_roll()` false

---

## Task 5. UI (칩·골드·상태 문구)

**목적:**
- 헤더 골드 표시, 칩 라벨, 골드 획득·리롤 안내

**수정 예상 파일:**
- `scenes/game/run_scene.tscn`
- `scripts/ui/run_scene.gd`

**수정 금지:**
- 상점 오퍼 가격 (이번 제외), score_phase_presenter 연출

**완료 조건:**
- 골드·칩 표시
- 상점 진입 시 골드 지급·문구 표시
- AC UI 항목 충족

---
