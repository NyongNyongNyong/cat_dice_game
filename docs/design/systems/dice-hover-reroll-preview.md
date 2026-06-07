# 주사위 Hover 리롤 Preview 시스템

> **문서 유형:** 시스템 스펙 (UI·계산 규칙)  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §4·§9 — Push Your Luck, 리롤  
> **점수 계산:** [hand-scoring-v2.md](hand-scoring-v2.md) — Preview는 **동일 계산기·동일 입력**을 사용  
> **상태:** v0.1 구현 완료 — `REROLL_READY` phase, Hover Preview, 선택 후 Roll로 단일 리롤  
> **구현:** `reroll_preview_calculator.gd` · `reroll_preview_result.gd` · `reroll_preview_presenter.gd` · `round_controller.gd` · `run_scene.gd` · `dice.gd`

---

## 1. 목적

플레이어가 특정 주사위를 리롤할지 판단할 수 있도록 돕는다.

플레이어는 Hover만으로 아래를 빠르게 파악할 수 있어야 한다.

- 이 주사위를 굴리면 **얼마나 좋아질 수 있는가?**
- 이 주사위를 굴리면 **얼마나 망할 수 있는가?**

---

## 2. 표시 정보

주사위에 **Hover** 시 해당 주사위 근처(또는 툴팁)에 변화량만 표시한다.

표기 예 (화살표 포함):

```text
▲ +440  ▼ -170
```

표기 예 (화살표 생략 허용):

```text
+440  -170
```

| 표기 | 의미 |
|------|------|
| `▲ +N` / `+N` | 현재 점수 대비 **최고** 결과 시 증가량 |
| `▼ -N` / `-N` | 현재 점수 대비 **최저** 결과 시 감소량 |

양수·음수 기호는 **현재 점수와의 차이**를 나타낸다. `+440`은 최대 440점 상승 가능, `-170`은 최대 170점 하락 가능을 뜻한다.

---

## 3. 계산 기준

**현재 상태 그대로**를 기준으로 한다. Preview 계산에 포함되는 요소:

| 포함 | 비고 |
|------|------|
| 현재 주사위 10개 눈금 | Hover 대상 1개만 가상 교체 |
| 현재 유물 | 구현 시점에 활성 효과 전부 |
| 현재 버프 | 일시 효과 포함 |
| 현재 상태 이상 | 점수·면에 영향 주는 디버프 등 |
| 현재 스테이지(층)·카지노 규칙 효과 | 라운드 컨텍스트 |
| 기타 점수 계산에 영향을 주는 모든 요소 | `HandCalculator` 입력과 동일 |

Preview는 **리롤 비용·칩·남은 리롤 횟수**를 바꾸지 않는다. 순수하게 “이 면이 바뀌면 점수가 어떻게 달라지는가”만 본다.

### 3.1 v0.1 구현 범위

| 포함 (현재 코드) | 미포함 (추후) |
|------------------|---------------|
| 현재 주사위 10개 눈금 (`RoundController.dice_values`) | 유물·버프·디버프 |
| `HandCalculator.evaluate(dice_values)` | `RunState` 모디파이어 스냅샷 |
| 기본 6면 `[1, 2, 3, 4, 5, 6]` 고정 | 주사위 리소스 `faces` · 카지노 규칙 |

---

## 4. 계산 방식

1. Hover된 주사위 인덱스 `i`를 선택한다.
2. 해당 주사위의 **가능한 모든 면**을 순회한다. (기본 6면 주사위면 6회; 특수 주사위는 실제 면 목록 사용)
3. 각 면 값 `v`로 `dice[i]`만 교체한 가상 배열을 만든다.
4. 각 가상 배열에 대해 **최종 점수**를 계산한다 (`HandCalculator` / v2 공식).
5. 가능한 결과 중 **최고 점수** `max_score`, **최저 점수** `min_score`를 찾는다.
6. 현재 점수 `current_score`와의 차이를 구한다.

```text
delta_up   = max_score - current_score
delta_down = min_score - current_score
```

7. UI에는 `▲ +{delta_up}`, `▼ {delta_down}` (음수는 `-` 포함)만 표시한다. v0.1은 **항상 화살표 포함** 형식을 사용한다.

**주의:** 현재 눈금과 동일한 면도 후보에 포함한다. 따라서 `delta_up`·`delta_down` 모두 0일 수 있다 (“건드려도 변화 거의 없음”).

**v0.1:** `RerollPreviewCalculator.DEFAULT_FACE_VALUES` = `[1, 2, 3, 4, 5, 6]`. 특수 주사위·가변 면은 미연동.

---

## 5. 예시

현재 점수:

```text
1440
```

Hover 주사위를 각 면으로 바꿨을 때 가능한 최종 점수:

```text
1270  1320  1440  1500  1660  1880
```

| 항목 | 값 |
|------|---:|
| `current_score` | 1440 |
| `max_score` | 1880 → `delta_up` = **+440** |
| `min_score` | 1270 → `delta_down` = **-170** |

Hover 표시:

```text
▲ +440  ▼ -170
```

---

## 6. UX 의도

Hover만으로 플레이어가 직관적으로 판단할 수 있게 한다.

| 패턴 | 해석 |
|------|------|
| `▲` 큼, `▼` 작음 | 잠재력 높음 — 리롤 가치 있음 |
| `▼` 큼, `▲` 작음 | 위험 — 리롤 시 하락 폭 큼 |
| `▲`·`▼` 모두 작음 | 건드려도 점수 변화 거의 없음 |

리롤 **결정 보조**이지, 리롤 실행·확정을 대체하지 않는다.

### 6.1 Phase (`RoundPhase`)

| Phase | Preview | Roll 버튼 | Next Floor |
|-------|---------|-----------|------------|
| IDLE | 비표시 | 활성 (10개 전부 굴림) | 비활성 |
| ROLLING | 비표시 | 비활성 | 비활성 |
| SCORING | 비표시 | 비활성 | 비활성 |
| REROLL_READY | 활성 | 선택 시만 활성 (단일 리롤) | 목표 달성 시 활성 |

`RoundController.can_reroll_preview()` · `can_advance_floor()` 모두 `REROLL_READY`일 때만 true.

### 6.2 플레이 흐름 (v0.1)

```text
Roll → 굴림 연출 + 점수 연출 → REROLL_READY
REROLL_READY: Hover Preview · 클릭(선택) · Roll(단일 리롤) 또는 Next Floor(목표 달성 시)
단일 리롤 → 값 즉시 반영 + 점수 연출 → REROLL_READY 복귀 (반복 가능)
```

| 단계 | 동작 |
|------|------|
| **Roll** (IDLE) | 10개 전부 굴림 (`RollPhasePresenter` 연출) → 점수 연출 → `REROLL_READY` |
| **Hover** (REROLL_READY) | 주사위 위 툴팁에 `▲ +N  ▼ -N` 표시. `mouse_exited` 시 숨김 |
| **클릭** | 해당 주사위 **선택** — 파란 테두리 (`dice.gd` `set_selected`) |
| **Roll** (선택 후) | 선택 주사위 1개만 `randi_range(1, 6)` 리롤 — **굴림 연출 없이** 눈금 즉시 갱신 → 점수 **재계산·연출** → `REROLL_READY` |
| **Next Floor** (목표 달성 시) | 리롤과 **병행 가능**. 층 이동 시 라운드 리셋 → `IDLE` |

v0.1은 **리롤 횟수 제한 없음**. 목표 점수를 넘긴 뒤에도 계속 리롤하거나 Next Floor로 진행할 수 있다.

### 6.3 상태 안내 (`StatusLabel`)

| 조건 (`REROLL_READY`) | 문구 |
|------------------------|------|
| 주사위 선택됨 | Roll을 눌러 선택한 주사위를 다시 굴리세요. |
| 미선택 + 목표 달성 | 목표 달성! Next Floor로 이동하거나, 주사위를 선택해 더 리롤할 수 있습니다. |
| 미선택 + 목표 미달 | 주사위에 마우스를 올려 리롤 효과를 확인하고, 클릭해 선택하세요. |

---

## 7. 성능

| 항목 | 값 |
|------|-----|
| 주사위 수 | 10 (고정) |
| 기본 면 수 | 6 |
| Hover 1회당 점수 계산 | **해당 주사위 면 수** (기본 최대 6회) |

주사위당 독립 계산이므로 실시간 Hover에 충분하다.

v0.1 구현 (`RerollPreviewPresenter`):

- 보드 키: 10개 눈금을 `,`로 join — 변경 시 전체 캐시 클리어
- 주사위 인덱스별 결과 캐시 — 동일 보드에서 재 Hover 시 재계산 생략
- 단일 리롤 완료 시 `invalidate_cache()` 호출
- `set_active(false)` 시 Preview 숨김 + 캐시 클리어
- debounce 없음 (6회 계산으로 충분)

---

## 8. 구현 메모

| 항목 | v0.1 구현 |
|------|-----------|
| 계산 | `RerollPreviewCalculator.compute()` → `RerollPreviewResult` |
| 점수 | `HandCalculator.evaluate()` — [hand-scoring-v2.md](hand-scoring-v2.md) 정본 |
| 입력 | `RoundController.dice_values` (모디파이어 없음) |
| 라운드 | `RoundController` — `select_die`, `_reroll_selected_die`, phase 전환 |
| UI 연동 | `run_scene.gd` — `mouse_entered` / `mouse_exited` / `gui_input`(클릭) |
| 툴팁 | `RerollPreviewPresenter` — `run_scene` `DiceRow/PopupOverlay` 위에 동적 생성, 주사위 중심 상단 (`offset y: -12`) |
| 선택 표시 | `dice.gd` — `set_selected` 파란 테두리 |
| 테스트 | `reroll_preview_calculator_spec_test.gd` — brute-force 대조 |
| 면 목록 (추후) | 주사위 리소스 `faces` |
| 모디파이어 (추후) | `RunState` 스냅샷 — API 도입 시 `compute()` 인자 확장 |

### 8.1 엣지 케이스

| 상황 | v0.1 동작 |
|------|-----------|
| ROLLING / SCORING | Preview 비표시 (`set_active(false)`) |
| 선택 없이 Roll (`REROLL_READY`) | Roll 버튼 비활성 |
| `mouse_exited` | 툴팁 숨김 |
| 단일 리롤 후 | 선택 해제, 캐시 무효화, SCORING → 점수 연출 → `REROLL_READY` |
| 보드(눈금) 변경 | 보드 키 불일치 시 캐시 클리어 후 재계산 |
| 면 1개만 있는 주사위 | `delta_up` = `delta_down` = 0 (계산기 `face_values` 인자) |
| 주사위 잠금(고정) | **미구현** — 추후: Preview 생략 또는 “고정됨” 표시 |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-07 | v0.1 구현 반영 — Next Floor 병행, 상태 문구, 단일 리롤 연출, 캐시·파일 매핑, v0.1 범위 표 |
| 2026-06-07 | v0.1 구현 완료 — `REROLL_READY`, Hover Preview, 선택+Roll 단일 리롤 |
| 2026-06-07 | 초안 — Hover 리롤 최고·최저 변화량 규칙·알고리즘·성능 |
