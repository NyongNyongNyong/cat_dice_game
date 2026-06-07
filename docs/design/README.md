# 설계 문서

**구현 설계** 정본. Godot `res://` 밖, repo `docs/design/`에 둔다.

## 기획 vs 설계

| 구분 | 경로 | 담는 내용 |
|------|------|-----------|
| **기획** | [`gdd-cat-tower-casino.md`](../gdd-cat-tower-casino.md) | 비전, 재미 축, 시스템 방향, 미정 항목 |
| **설계** | `docs/design/` | 씬·스크립트·데이터 구조, 구현 범위, 개발 환경 |

기획은 *무엇을* 만들지, 설계는 *어떻게* 만들지를 정의한다.  
설계 버전이 기획보다 좁을 수 있다(초기에는 핵심 루프만 구현).

## 버전 목록

| 버전 | 문서 | 요약 |
|------|------|------|
| v0.1 | [v0.1-initial-playable.md](v0.1-initial-playable.md) | 주사위 굴림·합산 점수·5층 진행 — 재미 검증용 최소 플레이어블 |

## 시스템 스펙

규칙·알고리즘 상세: [systems/README.md](systems/README.md)

| 스펙 | 요약 |
|------|------|
| [hand-scoring-v1.md](systems/hand-scoring-v1.md) | 족보 v1 (구현·레거시) |
| [hand-scoring-v2.md](systems/hand-scoring-v2.md) | **족보 v2 정본** (밸런스) |
| [dice-hover-reroll-preview.md](systems/dice-hover-reroll-preview.md) | Hover 리롤 Preview (최고·최저 변화량) |

## 수정 규칙

- 설계 변경 시 해당 문서 **본문을 직접 갱신**하고, 맨 하단 `## 변경 이력`에 날짜·한 줄 요약을 추가한다 (최신이 위).
- 기획(GDD)과 충돌하면 GDD가 방향의 정본이고, 설계는 *현재 구현 스코프*를 반영한다.
- 코드·식별자: 영문 `snake_case` / `PascalCase`. 설명 본문: 한국어.

## 개발 워크플로

- [feature-workflow.md](feature-workflow.md) — `/feature` → 피드백 → `/push` 플로우 (다이어그램 정본)

## 관련 문서

- [Godot 폴더 상세](../godot-project-layout.md)
- [데이터 계층](../data-hierarchy.md)

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-07 | feature-workflow.md 링크 추가 |
| 2026-06-07 | 수정 규칙 — 본문 최신 유지 + 하단 `## 변경 이력` 표준화 |
