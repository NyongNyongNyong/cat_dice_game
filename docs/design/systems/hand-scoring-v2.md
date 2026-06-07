# 족보 계산 시스템 v2

> **문서 유형:** 시스템 스펙 (규칙·알고리즘·밸런스)  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §9  
> **이전:** [hand-scoring-v1.md](hand-scoring-v1.md) (가치=1, Straight/Stair 계층 누적)  
> **구현:** `game/scripts/core/hand_calculator.gd` — **v2 반영 완료.** **정본(밸런스·규칙): 본 문서.**  
> **상태:** v2 플레이테스트용 밸런스 초안 · 코드 동기화됨

---

## 1. 점수 공식

```
점수 = Σ(숫자) × Σ(족보 가치)
```

| 항목 | 정의 |
|------|------|
| **Σ(숫자)** | 주사위 10개 눈금 합 |
| **Σ(족보 가치)** | 획득한 모든 족보의 `(획득 횟수 × 족보별 가치)` 합 |

구현:

```text
number_sum      = Σ(dice)
hand_value_sum  = Σ(count × value)
final_score     = number_sum × hand_value_sum
```

---

## 2. 공통 규칙

### 2.1 계열 간 독립 계산

모든 **계열**은 원본 주사위 결과를 기준으로 **독립** 계산한다.

예: `11111`

| 계열 | 획득 (독립) |
|------|-------------|
| Pair | Pair ×2, Two Pair ×1 |
| Triple | Triple ×1 |
| Quad | Quad ×1 |
| Penta | Penta ×1 |
| … | 각 계열 규칙 적용 |

### 2.2 계열 내부 재료 소모

**같은 계열** 안에서만 재료를 소모한다.

### 2.3 조합론(CnR) 금지

```text
11111 → Pair ×10   ❌
```

---

## 3. Pair 계열

### 3.1 계산

```text
pair_bundle_count = Σ floor(count / 2)    # 숫자별 count 합산
```

| 족보 | 획득 수 |
|------|---------|
| Pair | floor(pair_bundle_count / 1) |
| Two Pair | floor(pair_bundle_count / 2) |
| Three Pair | floor(pair_bundle_count / 3) |
| Four Pair | floor(pair_bundle_count / 4) |
| Five Pair | floor(pair_bundle_count / 5) |

### 3.2 가치

| 족보 | 가치 |
|------|-----:|
| Pair | 1 |
| Two Pair | 2 |
| Three Pair | 4 |
| Four Pair | 7 |
| Five Pair | 11 |

---

## 4. Triple 계열

### 4.1 계산

```text
triple_bundle_count = Σ floor(count / 3)
```

| 족보 | 획득 수 |
|------|---------|
| Triple | floor(triple_bundle_count / 1) |
| Two Triple | floor(triple_bundle_count / 2) |
| Three Triple | floor(triple_bundle_count / 3) |

### 4.2 가치

| 족보 | 가치 |
|------|-----:|
| Triple | 3 |
| Two Triple | 10 |
| Three Triple | 22 |

---

## 5. Quad 계열

### 5.1 계산

```text
quad_bundle_count = Σ floor(count / 4)
```

| 족보 | 획득 수 |
|------|---------|
| Quad | floor(quad_bundle_count / 1) |
| Two Quad | floor(quad_bundle_count / 2) |

### 5.2 가치

| 족보 | 가치 |
|------|-----:|
| Quad | 8 |
| Two Quad | 28 |

---

## 6. Penta 계열

### 6.1 계산

```text
penta_bundle_count = Σ floor(count / 5)
```

| 족보 | 획득 수 |
|------|---------|
| Penta | floor(penta_bundle_count / 1) |
| Two Penta | floor(penta_bundle_count / 2) |

### 6.2 가치

| 족보 | 가치 |
|------|-----:|
| Penta | 16 |
| Two Penta | 60 |

---

## 7. High Kind 계열

### 7.1 계산

```text
획득 수 = Σ floor(count / 필요 개수)    # 족보별, 숫자별 합산
```

### 7.2 가치

| 족보 | 필요 개수 | 가치 |
|------|----------:|-----:|
| Hexa | 6 | 28 |
| Hepta | 7 | 45 |
| Octa | 8 | 70 |
| Nona | 9 | 100 |
| Deca | 10 | 140 |

---

## 8. Straight 계열

### 8.1 족보·가치

| 족보 | 길이 | 가치 |
|------|-----:|-----:|
| 5 Straight | 5 | 8 |
| 6 Straight | 6 | 16 |
| 7 Straight | 7 | 28 |
| 8 Straight | 8 | 44 |
| 9 Straight | 9 | 64 |
| 10 Straight | 10 | 90 |

### 8.2 계산 규칙

1. 만들 수 있는 **최장 Straight 길이**를 찾는다.
2. 해당 길이 Straight를 **재료 소모** 방식으로 최대 몇 개 만들 수 있는지 계산한다.
3. **하위 Straight는 획득하지 않는다.** (v1과 다름)

### 8.3 예시

| 입력 | 결과 |
|------|------|
| `123456` | 6 Straight ×1 |
| `1122334455` | 5 Straight ×2 |

> **기본 주사위(1~6):** 최장 Straight는 6. 7~10 Straight는 면 확장·특수 주사위 도입 시 사용.

---

## 9. Full House

| 항목 | 내용 |
|------|------|
| 조건 | Triple 1개 + Pair 1개 (서로 다른 숫자) |
| 가치 | **8** |
| 계산 | **Full House 전용 pool**에서 Triple·Pair 묶음을 **재료 소모**하여 최대 획득 수 |

> **§2.1 주의:** Pair·Triple **계열**과 Full House는 **독립** 계산.  
> Triple/Pair 계열 chunk 목록을 그대로 조합하면 **주사위가 중복**되어 틀린다.  
> Full House는 원본 주사위로 pool을 만들고, 풀하우스 1회마다 3+2 주사위를 **소모**한다.

### 9.1 알고리즘

```text
1. face별 주사위 index pool (원본 기준)
2. loop:
     triple 가능 face T, pair 가능 face P (T ≠ P) 찾기
     없으면 종료
     pool[T]에서 3개, pool[P]에서 2개 제거 → Full House +1
3. 최대 반복
```

### 9.2 예시

| 입력 | 결과 |
|------|------|
| `11122` | Full House ×1 |
| `1112223344` | Full House ×2 (111+33, 222+44 등) |
| `3433462145` | Full House ×1 (333+44, 3×3·4×3) |

---

## 10. Stair 계열

### 10.1 개념

연속된 숫자의 **동일 등급 묶음**.

- Pair Stair: `11-22-33` …
- Triple Stair: `111-222-333` …

### 10.2 Pair Stair

| 족보 | 길이 | 가치 |
|------|-----:|-----:|
| 2 Pair Stair | 2 | 5 |
| 3 Pair Stair | 3 | 10 |
| 4 Pair Stair | 4 | 18 |
| 5 Pair Stair | 5 | 30 |

### 10.3 Triple Stair

| 족보 | 길이 | 가치 |
|------|-----:|-----:|
| 2 Triple Stair | 2 | 24 |
| 3 Triple Stair | 3 | 50 |

### 10.4 Quad Stair

| 족보 | 길이 | 가치 |
|------|-----:|-----:|
| 2 Quad Stair | 2 | 70 |

### 10.5 Penta Stair

| 족보 | 길이 | 가치 |
|------|-----:|-----:|
| 2 Penta Stair | 2 | 120 |

### 10.6 계산 규칙

1. 해당 Stair **계열**에서 만들 수 있는 **최장 길이**를 찾는다.
2. 해당 길이 Stair를 **재료 소모** 방식으로 최대 몇 개 만들 수 있는지 계산한다.
3. **하위 Stair는 획득하지 않는다.** (v1과 다름)

### 10.7 예시

| 입력 | 결과 |
|------|------|
| `112233` | 3 Pair Stair ×1 |
| `1122334455` | 5 Pair Stair ×1 |

(v1 예시 `1122334455` → 2/3/4/5 Pair Stair 동시 획득과 **다름**)

---

## 11. 전체 족보 목록 (29종)

| 계열 | 족보 |
|------|------|
| Pair | Pair, Two Pair, Three Pair, Four Pair, Five Pair |
| Triple | Triple, Two Triple, Three Triple |
| Quad | Quad, Two Quad |
| Penta | Penta, Two Penta |
| High Kind | Hexa, Hepta, Octa, Nona, Deca |
| Straight | 5~10 Straight |
| Full House | Full House |
| Stair | 2~5 Pair Stair, 2~3 Triple Stair, 2 Quad Stair, 2 Penta Stair |

---

## 12. v1 대비 변경 요약

| 항목 | v1 | v2 |
|------|----|----|
| 족보 가치 | 전부 1 | 계열별 테이블 (§3~10) |
| Pair~Penta | `floor(count/n)` 개별 족보 | **bundle → 계열 내 tier** (Pair / Two Pair / …) |
| Straight | 하위 누적 (6→5 동시) | **최장만** |
| Stair | 하위 누적 (5→4→3→2 동시) | **최장만** |
| 족보 수 | 22종 | **29종** |
| `1122334455` | Pair×5, 5 Straight×2, Stair 4종 | Pair·Straight·Stair 규칙 v2 적용 (Stair는 5 Pair Stair×1 등) |

---

## 13. 점수 연출 (`ScorePhasePresenter`) — v0.1

`HandCalculator.evaluate()`가 반환하는 `HandStep` 배열 순서대로 좌(숫자 합)·우(족보 가치) 패널을 채운다.

### 13.1 `HandStep` 하이라이트

각 step의 `highlight_indices`는 **해당 step이 점수에 기여한 주사위 인덱스만** 담는다. 이전 step과 **누적하지 않는다.**

| 계열 | 하이라이트 범위 |
|------|-----------------|
| Pair~Penta bundle | tier instance마다 `divisor`개 chunk 중 **해당 instance 구간만** (`start_chunk` ~ `end_chunk`) |
| High Kind | formation 1회분 (예: Hexa 6개) |
| Straight | formation 1회분 |
| Full House | triple 3 + pair 2 |
| Stair | formation 1회분 |

연출 시 step마다 `_apply_highlights(step.highlight_indices)`로 **교체**한다. 계열·tier가 바뀔 때 하이라이트를 비우는 tier reset·`clear_before` 지연은 **사용하지 않는다** (v0.1).

### 13.2 연출 순서

1. 숫자 합 — 주사위 1개씩 순회, `+N` 팝업
2. 족보 step — 하이라이트 → 포커스 이동 → 우측 패널 누적 → 족보 팝업

단일 리롤 후에도 동일 연출을 재생한다 (`round_controller` → `score_ready`).

---

## 14. 구현 메모

| 항목 | 방향 |
|------|------|
| `HandCalculator` | v2 계열·tier·가치 테이블 · step별 청크 하이라이트 (§13.1) |
| `hand_calculator_spec_test.gd` | **스펙 예시 회귀 테스트** — 문서 예시와 불일치 시 실패 |
| `hands.json` | id, display_ko, value, tier 규칙 메타 (detect는 코드) |
| `ScorePhasePresenter` | §13 연출 순서·하이라이트 교체 |
| 층 목표 점수 | v2 점수 스케일에 맞게 재조정 필요 |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-07 | §13 점수 연출 — HandStep 청크 단위 하이라이트, tier reset 미사용 (v0.1 구현 반영) |
| 2026-06-05 | §9 Full House — pool 소모 알고리즘·예시 보강 (Triple/Pair chunk 재사용 금지) |
| 2026-06-05 | `hand_calculator.gd` 구현 — bundle tier, Straight/Stair 최장만 |
| 2026-06-05 | 플레이테스트 밸런스 — 29종 가치표 |
| 2026-06-05 | [hand-scoring-v1.md](hand-scoring-v1.md)에서 분기 — 레거시 (가치=1) |
