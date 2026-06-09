# 시스템 스펙

**규칙·알고리즘** 정본. 플레이어블 설계(`v0.1-…`)보다 세부적이고, GDD보다 구체적이다.

| 문서 | 요약 |
|------|------|
| [hand-scoring-v2.md](hand-scoring-v2.md) | **족보 v2 정본** — 밸런스·bundle tier, 29종 · `hand_calculator.gd` |
| [dice-resources.md](dice-resources.md) | **주사위 리소스·면 정본** — `DiceResource`, `NumberFace`/`SpecialFace`, `FaceProperty`, 해석·UI |
| [dice-catalog.md](dice-catalog.md) | **주사위 카탈로그** — JSON 6면 정의, id 기반 로스터·상점 |
| [dice-roster-shop.md](dice-roster-shop.md) | **보유 로스터·상점** — 시작 4기본, 층 간 교체·확장 골격 |
| [dice-hover-reroll-preview.md](dice-hover-reroll-preview.md) | Hover 리롤 Preview — 주사위별 최고·최저 점수 변화량 표시 |
| [hand-scoring-v1.md](hand-scoring-v1.md) | 족보 v1 — 레거시 (가치=1) |

## 왜 분리?

- GDD: 방향·재미 축 (짧게 유지)
- 플레이어블 설계 (`v0.1-…`): 구현 범위·씬·phase
- **시스템 스펙**: 계산 규칙·예시·엣지 케이스 (길어도 OK)

구현 시 `scripts/core/`의 계산기는 **이 폴더의 스펙**을 따른다.

## 수정 규칙

- 규칙 변경 시 해당 스펙 문서 **본문을 직접 갱신**하고, 맨 하단 `## 변경 이력`에 날짜·한 줄 요약을 추가한다 (최신이 위).
- 족보 **가치(밸런스)** 변경은 `game/data/scoring/hands.json`과 함께 반영.
- GDD §9 점수 공식과 충돌하면 GDD가 방향 정본, 스펙은 계산 상세 정본.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | `dice-catalog.md` 추가 — JSON 카탈로그·DiceCatalogService |
| 2026-06-08 | `dice-roster-shop.md` 추가 — 보유 주사위·상점 골격 |
| 2026-06-08 | `dice-resources.md` 추가 — TwoEG 면 리소스 구현 정본 |
| 2026-06-07 | 수정 규칙 — 하단 `## 변경 이력` 표준화 (`날짜 \| 변경`, 최신이 위) |
