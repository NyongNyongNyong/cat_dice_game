# 상점 compact 레이아웃

> **문서 유형:** UI 레이아웃 스펙  
> **관련:** [shop-scene.md](shop-scene.md) · [shop-purchase.md](shop-purchase.md)  
> **구현:** `shop_scene.tscn` · `shop_scene.gd` · `dice_shop_presenter.gd`

---

## 1. 목적

1280×720 뷰포트에서 상점 UI가 **불필요하게 스크롤되지 않도록** 여백·위젯 크기를 줄인다.

---

## 2. 레이아웃

| 항목 | compact |
|------|---------|
| 주사위 위젯 | 44×44 px |
| 보유 슬롯 | `GridContainer` **2열** |
| 헤더 | `상점 · 층 N` + 골드 (별도 대제목 제거) |
| 바깥 여백 | 20 / 12 px |
| `ScrollContainer` | 유지 — 콘텐츠 초과 시에만 스크롤 |

`RosterSlots` 노드 타입은 `GridContainer`. `shop_scene.gd`의 `@onready` 타입과 **일치**해야 한다.

---

## 3. 수용 기준

- [x] 720p에서 기본 4슬롯·오퍼 3종이 스크롤 없이 표시
- [x] 구매·교체·Hover·다음 층 동작 유지
- [x] `GridContainer` 타입 불일치로 씬이 깨지지 않음

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | compact 레이아웃 + GridContainer 타입 수정 |
