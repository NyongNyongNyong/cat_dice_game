# 상점 독립 씬

> **문서 유형:** UI 시스템 스펙  
> **관련:** [dice-roster-shop.md](dice-roster-shop.md) — 상점 기능·오퍼  
> **구현:** `shop_scene.tscn` · `shop_scene.gd` · `game_flow.gd` · `main.gd`

---

## 1. 목적

상점 UI를 `run_scene` 내부 패널에서 **독립 씬**으로 분리한다.

| 문제 | 해결 |
|------|------|
| 해상도에 따라 상점 패널 잘림 | Full Rect + ScrollContainer |
| 플레이 UI와 상점 UI 혼재 | 씬 전환으로 분리 |
| 상점 기능 확장 | 독립 레이아웃·스크립트 |

---

## 2. 씬 구조

```text
Main (Control, Full Rect) — main.gd
  UI (Control, Full Rect)
    RunScene | ShopScene  ← GameFlow로 교체

ShopScene (Control, Full Rect)
  Background (ColorRect, Full Rect)
  MarginContainer (Full Rect)
    RootVBox
      Header (층, 골드)
      Title / StatusLabel
      ScrollContainer (expand)
        ScrollContent (VBox)
          OfferPanel
          RosterHeading
          RosterSlots (동적)
      Footer — ContinueButton
  DiceShopPresenter (Node)
```

- **Container 기반** 레이아웃만 사용. 절대 좌표 배치 금지.
- 상품·슬롯 목록은 `ScrollContainer` 내부.

---

## 3. 씬 전환

| Autoload | 역할 |
|----------|------|
| `GameFlow` | `show_run()` / `show_shop()` 시그널 |
| `Main` | `UI` 자식을 RunScene ↔ ShopScene 스왑 |

| 트리거 | 동작 |
|--------|------|
| Next Floor (목표 달성) | `RunManager.enter_shop()` → `GameFlow.show_shop()` |
| 상점 **다음 층** | `RunManager.advance_floor()` → `GameFlow.show_run()` |

`RunManager`가 런 상태(로스터·골드·층)를 유지. RunScene 재진입 시 `start_run()`은 **최초 1회만**.

---

## 4. 기능 이전 (MVP)

기존 `DiceShopPresenter` + `run_scene` 상점 패널과 동일:

- 교체 오퍼 `dice_triple_h`
- 슬롯별 **교체** 버튼
- **다음 층** → 층 진행

`run_scene`에서 `ShopPanel`·`DiceShopPresenter` **제거**.

---

## 5. 수용 기준

- [x] Next Floor → 독립 상점 화면 전환
- [x] ScrollContainer로 슬롯 많아도 잘리지 않음
- [x] 교체·다음 층 동작 유지
- [x] 상점 → RunScene 복귀 후 새 층 라운드 시작
- [x] `run_scene`에 상점 패널 없음

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 독립 shop_scene, GameFlow, Main 셸 |
| 2026-06-09 | AC 반영 — 구현 완료 체크 |
