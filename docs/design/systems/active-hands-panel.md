# 활성 족보 패널 (Active Hands)

> **문서 유형:** UI 시스템 스펙  
> **점수·족보:** [hand-scoring-v2.md](hand-scoring-v2.md) — `HandCalculator.evaluate`  
> **구현:** `active_hands_presenter.gd` · `score_phase_presenter.gd` · `hand_calculator.gd` · `run_scene.tscn`

---

## 1. 목적

점수 연출 중·후 **현재 보드에서 인정된 족보**를 우측 사이드바에 요약 표시한다.

예: `페어 : 2`, `투페어 : 1`

우측 점수판(`RightPanel`)의 **족보 합 숫자**와 분리 — 숫자는 기존 유지, 목록만 추가.

---

## 2. UI

| 노드 | 역할 |
|------|------|
| `ActiveHandsSidebar` | 우측 앵커 패널 |
| `ActiveHandsList` | `ScrollContainer` 내부 VBox |
| `ActiveHandsPresenter` | 행 생성·갱신 |

- Container 기반. 절대 좌표 금지.
- 족보 없음: `—` 힌트 1줄.

---

## 3. 데이터

`HandCalculator.summarize_steps(steps)` → `Array[Dictionary]`:

| 필드 | 설명 |
|------|------|
| `hand_id` | 족보 id |
| `display_ko` | 표시명 (예: `페어`) |
| `count` | 동일 족보 step 개수 |

점수 연출(`ScorePhasePresenter`)이 step을 누적할 때마다 목록 갱신. 라운드 리셋 시 `clear()`.

---

## 4. 수용 기준

- [x] Roll·리롤 점수 연출 후 활성 족보가 우측 목록에 표시
- [x] 동일 족보 여러 step은 `: N`으로 합산
- [x] 라운드 리셋 시 목록 초기화
- [x] 족보 점수 공식·`hand-scoring-v2` 규칙 변경 없음

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 우측 ActiveHandsSidebar, summarize_steps |
