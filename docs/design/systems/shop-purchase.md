# 상점 골드 구매·교체

> **문서 유형:** UI·경제 시스템 스펙  
> **관련:** [dice-roster-shop.md](dice-roster-shop.md) · [gold-economy.md](gold-economy.md) · [shop-scene.md](shop-scene.md)  
> **구현:** `shop_offer_service.gd` · `dice_shop_presenter.gd` · `shop_scene.gd` · `run_manager.gd`

---

## 1. 목적

상점에서 **골드를 지불**해 주사위를 구매하고, 보유 슬롯 주사위와 **교체**한다.

| 이전 (MVP) | 이번 |
|------------|------|
| 고정 오퍼 1종, 무료 교체 | 고정 오퍼 3종, 골드 차감 |
| 슬롯별 교체 버튼 | **구매 주사위 클릭 → 교체 슬롯 클릭** |

---

## 2. 구매 가능 주사위 (v0.1 고정)

랜덤 풀은 추후. 현재 `data/economy/shop_offers.json`:

| id | 면 | 특수 면 효과 | 가격 |
|----|-----|-------------|------|
| `dice_triple_h` | 1,1,1 + H,H,H | 보드 **숫자면 중 최고** | 2골드 |
| `dice_triple_l` | 3,3,3 + L,L,L | 보드 **숫자면 중 최저** | 2골드 |
| `dice_triple_v` | 2,2,2 + V,V,V | 보드에 **없는 숫자 중 최저** (1~6) | 3골드 |

표기: H / L / V 문양. pip·문양만 — 아라비아 숫자 텍스트 금지.

---

## 3. 동선 (UX)

1. 상점 진입 — 헤더 골드·상태 문구 표시.
2. **구매 행** — 오퍼 3개 카드 (미리보기 면 + 이름 + 가격). **클릭** → 선택(파란 테두리).
3. **보유 행** — 슬롯별 미리보기 면 + 이름. 선택된 오퍼가 있을 때 **클릭** → 골드 차감 + 교체.
4. 같은 오퍼 재클릭 → 선택 해제.
5. 골드 부족 오퍼 — 회색, 클릭 불가.
6. **다음 층** — 기존과 동일 (`advance_floor` → RunScene).

### Hover (유지)

- 오퍼·보유 주사위 위젯 **마우스 오버** → 6면 미니 툴팁 (`RerollPreviewPresenter`).
- 슬롯 미리보기 면: [dice-resources.md](dice-resources.md) `get_roster_preview_face()` — 특수면 우선, 없으면 최고 pip.

---

## 4. 계산·경제

- `RunManager.try_purchase_shop_replace(dice_id, slot_index)` — 가격 확인 → 로스터 교체 → 골드 차감.
- 가격表: `ShopOfferService` ← `shop_offers.json`.
- 족보·칩 공식 **미변경**.

---

## 5. 수용 기준

- [x] 오퍼 3종 고정 표시 (H / L / V)
- [x] 구매 클릭 → 슬롯 클릭 2단계 교체
- [x] 골드 차감, 부족 시 구매 불가
- [x] 보유·오퍼 주사위 면 미리보기 + Hover 6면
- [x] 다음 층 후 교체 반영

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 골드 구매, H/L/V 3종, 2단계 교체 UX |
