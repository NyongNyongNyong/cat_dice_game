# Task: 주사위 카탈로그 (dice-catalog)

## Task 1. 스펙·데이터

**목적:** 카탈로그 JSON v2, starter_loadout, GDD 연계 문서

**수정 예상 파일:**
- `docs/design/systems/dice-catalog.md`
- `docs/design/systems/README.md`
- `game/data/dice/dice_defs.json`
- `game/data/dice/starter_loadout.json`

**수정 금지:** 족보·점수 스펙

**완료 조건:** `dice_basic`·`dice_triple_h` 6면 정의, starter 4기본

---

## Task 2. DiceCatalog Autoload

**목적:** JSON → `DiceResource` 빌드·캐시·starter id 목록

**수정 예상 파일:**
- `game/scripts/autoload/dice_catalog.gd`
- `game/project.godot`
- `game/scripts/core/dice_catalog_spec_test.gd`

**완료 조건:** id 조회, 6면 검증 테스트 통과

---

## Task 3. 로스터·RunManager

**목적:** id 기반 보유·교체, H 하드코딩 제거

**수정 예상 파일:**
- `game/scripts/core/dice_roster.gd`
- `game/scripts/autoload/run_manager.gd`
- `game/scripts/core/dice_roster_spec_test.gd`

**완료 조건:** `replace_at_index(slot, dice_id)` 동작

---

## Task 4. 상점 UI

**목적:** 오퍼 id 기반 교체 버튼

**수정 예상 파일:**
- `game/scripts/ui/dice_shop_presenter.gd`
- `game/scripts/ui/run_scene.gd`

**완료 조건:** `dice_triple_h`로 교체 가능

---

## Task 5. 연관 스펙 갱신

**목적:** dice-resources, dice-roster-shop 정본 링크

**수정 예상 파일:**
- `docs/design/systems/dice-resources.md`
- `docs/design/systems/dice-roster-shop.md`

**완료 조건:** `.tres` 단독 정본 서술 제거, 카탈로그 참조

---
