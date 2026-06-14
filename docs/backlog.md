# 백로그

> **정본** — 앞으로 할 일·아이디어. feature로 뽑을 때 `/feature` → `docs/design/systems/<slug>.md` + `tasks/<slug>-tasks.md`.  
> Obsidian `Obsidian/Dice Cat Tower/TODO.md`는 개인 메모; **갱신은 이 파일 기준.**

---

## 단기

### 플레이 화면 — 활성 족보

- [x] 점수 연출 후 **인정된 족보** 목록 — [active-hands-panel.md](design/systems/active-hands-panel.md)

### 상점

- [x] 상점 **독립 씬** — [shop-scene.md](design/systems/shop-scene.md)
- [x] 골드 지불 **H / L / V** 구매·교체 — [shop-purchase.md](design/systems/shop-purchase.md)
- [x] compact 레이아웃 (720p) — [shop-layout-compact.md](design/systems/shop-layout-compact.md)

### 골드(칩) 오버킬 보상

- [x] 오버킬 골드 v2 (로그 임계 `r=2`, `n×(n+1)/2`) — [gold-economy.md](design/systems/gold-economy.md)
- [ ] **더 soft한 감쇠** 튜닝 (예: 목표 1×→1G, 2×→2G, 4×→4G… 느낌과 v2 비교·조정)

### 주사위 콘텐츠

- [ ] **최소 30종** 주사위 (카탈로그·상점·밸런스)
- **현재 제안된 특수 면** (참고 — v0.1 일부만 구현):
  - **H** — 최고 눈금 복사 → [x] `dice_triple_h` — [shop-purchase.md](design/systems/shop-purchase.md)
  - **L** — 최저 눈금 복사 → [x] `dice_triple_l`
  - **V** — 보드에 **등장하지 않은** 눈금 중 최소 **또는** 최대 → [x] `dice_triple_v` (현재 **최소**만; 최대 variant 미정)

### 아이템

- [ ] **최소 30종** 아이템 (유물·소모 등 — GDD·데이터 스펙 선행)

### 주사위 면 Preview

- [x] 6면 Hover 툴팁 (플레이·상점) — [dice-hover-reroll-preview.md](design/systems/dice-hover-reroll-preview.md)
- [x] 굴리기 전 슬롯 **미리보기 면** (특수면 / 최고 pip) — [dice-resources.md](design/systems/dice-resources.md)
- [ ] 6면이 아닌 주사위 형태 Preview (추후)

---

## 장기

### 리롤

- [ ] **리롤 시스템** — 유지·개편·**제거** 포함 방향 논의
- [ ] 논의 결과 반영 **최소 구현** + 플레이·headless **테스트**

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | 주사위 30종·아이템 30종·H/L/V 제안·리롤 논의 항목 추가 |
| 2026-06-09 | 미확정 족보 UI 항목 제거, 리롤 장기 항목을 방향 미정으로 |
| 2026-06-09 | Obsidian TODO 이관, 완료 항목 체크·스펙 링크 |
