# 백로그

> **읽기 쉬운 칸반:** [board/](board/) (GitHub Pages: `/board/`) — **7열** · 카드=`cards/<id>.md` · [`board/cards.json`](board/cards.json).  
> **정본 메모** — 앞으로 할 일·아이디어. feature로 뽑을 때 `/feature` → `docs/design/systems/<slug>.md` + `tasks/<slug>-tasks.md`.  
> Obsidian `Obsidian/Dice Cat Tower/TODO.md`는 개인 메모; **보드와 어긋나면 cards.json을 맞춘 뒤 이 파일도 갱신.**  
> **기획 방향:** [gdd-cat-tower-casino.md](gdd-cat-tower-casino.md) §4 (2026-06-21)  
> **v0.2 구현 현황:** [design/systems/v0.2-board-luck.md](design/systems/v0.2-board-luck.md) · [design/tasks/v0.2-board-luck-tasks.md](design/tasks/v0.2-board-luck-tasks.md)

---

## v0.2 (진행 중)

### 보드 (3×4) — Phase A **완료**

- [x] 3행×4열 그리드(12칸), 시작 4칸 해금·4주사위 — `run_scene` + `RunManager`
- [x] 클릭 배치(트레이→보드), 배치된 주사위만 굴림·족보·점수
- [x] 최대 보유 8주사위 (`MAX_OWNED_DICE`)
- [x] `unlock_next_slot()` API — `board_spec_test` PASS
- [ ] 슬롯 해금 **상점·비용** 연동 (GDD §11 미정)
- [x] 드래그 앤 드롭 배치 (클릭 배치와 병행)
- [ ] 빈칸 위치 효과 (GDD §4.1 추후)

### 행운 (Luck) — Phase B **핵심 완료**

- [x] `LuckResolver` — `6^k` 전수 + 로그 스케일 행운 컷
- [x] 굴림 플로우 통합, 행운 수치 UI 노출
- [x] 골드 리롤 경제 제거 (주사위 1개 리롤 — **폐기**)
- [x] 플레이 화면 hover 6면 툴팁 — `face_preview_presenter` ([dice-face-hover-preview.md](design/systems/dice-face-hover-preview.md))
- [ ] `luck` 변동 소스 (주사위·유물 등) — 현재 기본 0
- [ ] `REROLL_READY` phase 리네이밍 + 죽은 reroll 코드 정리 (`reroll_preview_calculator*` 등)

### 주사위 성장 (미착수)

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

- [ ] 강화 키트 상점·적용 UI (v0.2 Phase C)
- [ ] 카지노 규칙·유물·직원 등 GDD §11 확정 항목

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | 웹 칸반(`docs/board/`) 추가 — 가독용 보드, 데이터는 cards.json |
| 2026-07-04 | 칩=굴림 재화 확정 — 단발굴림·칩제거 가설 삭제, 드래그·hover 완료 반영, reroll 잔재 정리 항목 구체화 |
| 2026-06-30 | v0.2 보드·행운 Phase A/B 완료 반영, 중복 마이그레이션 섹션 제거 |
| 2026-06-21 | GDD §4 반영 — v0.2 백로그 섹션 추가, 리롤 항목을 행운·이행으로 정리 |
| 2026-06-09 | 주사위 30종·아이템 30종·H/L/V·리롤 논의 |
| 2026-06-09 | Obsidian TODO 이관 |
