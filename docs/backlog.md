# 백로그

> **정본** — 앞으로 할 일·아이디어. feature로 뽑을 때 `/feature` → `docs/design/systems/<slug>.md` + `tasks/<slug>-tasks.md`.  
> Obsidian `Obsidian/Dice Cat Tower/TODO.md`는 개인 메모; **갱신은 이 파일 기준.**  
> **기획 방향:** [gdd-cat-tower-casino.md](gdd-cat-tower-casino.md) §4 (2026-06-21)

---

## v0.2 방향 (기획 확정 — 구현 전)

### 보드 (3×4)

- [ ] 3×4 그리드, 시작 4슬롯·4주사위
- [ ] 슬롯 해금 (최대 12칸) — 비용·상점 연동 **미정**
- [ ] 최대 보유 8주사위 — 빈칸 전략
- [ ] **배치 → 굴림 → 효과 → 족보 → 점수** 플로우

### 행운 (Luck)

- [ ] 결과 분포 컷 알고리즘 (로그 스케일 행운)
- [ ] v0.1 **리롤·칩 소비** 제거/대체 이행 계획
- [ ] UI: 행운 수치만 노출 (내부 로직 비공개)

### 주사위 성장

- [ ] 강화 키트: 숫자 +1 / −1 / 진화(특수면)
- [ ] 교체 시 기존 주사위 처리 — 판매·폐기·재활용 **미정**

### 족보·특수면

- [ ] 족보 시스템 상세·밸런스 (v2 초안 유지 여부 검토)
- [ ] 특수면 종류 확장 (H/L/V는 v0.1 과도기)

---

## 단기 (v0.1 유지·마무리)

### 플레이 화면

- [x] 활성 족보 — [active-hands-panel.md](design/systems/active-hands-panel.md)
- [ ] `feature/script-preloads` — `.godot` 캐시 없이 CLI 파싱

### 상점

- [x] 독립 씬 · H/L/V 구매·교체 · compact — 각 스펙 문서

### 골드

- [x] 오버킬 골드 v2 — [gold-economy.md](design/systems/gold-economy.md)
- [ ] soft 감쇠 튜닝

### 콘텐츠

- [ ] 주사위 **30종** · 아이템 **30종** (GDD §11 선행)

### Preview

- [x] 6면 hover · 굴리기 전 미리보기
- [ ] 비 6면 주사위 preview

---

## 장기

### v0.1 → v0.2 마이그레이션

- [ ] 보드 UI·`RoundController` 배치 단계
- [ ] `RunManager` 8주사위·슬롯 해금
- [ ] 행운 스탯·`LuckResolver` (가칭)
- [ ] 리롤·reroll preview 코드 제거
- [ ] 강화 키트 상점·적용 UI

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-21 | GDD §4 반영 — v0.2 백로그 섹션 추가, 리롤 항목을 행운·이행으로 정리 |
| 2026-06-09 | 주사위 30종·아이템 30종·H/L/V·리롤 논의 |
| 2026-06-09 | Obsidian TODO 이관 |
