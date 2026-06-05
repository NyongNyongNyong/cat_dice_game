# 족보 계산 시스템 v1

> **문서 유형:** 시스템 스펙 (규칙·알고리즘)  
> **기획 참조:** [gdd-cat-tower-casino.md](../../gdd-cat-tower-casino.md) §9  
> **구현:** `scripts/core/hand_calculator.gd` · `score_calculator.gd` · `score_phase_presenter.gd`  
> **데이터:** `game/data/scoring/hands.json` (가치 테이블 — 추후)  
> **상태:** v1 — 계산·연출 구현됨

---

## 1. 핵심 철학

캣타워 카지노의 족보는 **포커처럼 가장 높은 족보 하나**를 고르는 게임이 아니다.

- 주사위 결과에서 **발견 가능한 모든 족보**를 계산한다.
- 플레이어는 **하나의 굴림**에서 **여러 족보를 동시에** 획득할 수 있다.

---

## 2. 점수와의 관계 (GDD §9)

```
라운드 점수 = Σ(숫자) × Σ(족보 가치)
```

- **Σ(숫자):** 10개 주사위 면 값 합 (v0.1과 동일)
- **Σ(족보 가치):** 이번 굴림에서 획득한 **모든 족보**의 `(획득 횟수 × 족보별 가치)` 합

### v1 가정

| 항목 | v1 |
|------|-----|
| 족보별 가치 | **전부 1** (밸런스는 추후 `hands.json`) |
| 입력 | 기본 주사위 10개, 면 값 `1~6` (v1 스펙은 pip 기준) |

---

## 3. 계산 원칙

### 3.1 순차 독립 카운트

모든 족보는 **원본 주사위 결과**를 기준으로 **독립** 계산한다.

- Pair 계산에 쓰인 주사위가 Triple 계산에 **영향을 주지 않는다**.

예: `11111`

| 족보 | 획득 |
|------|------|
| Pair | ×2 |
| Triple | ×1 |
| Quad | ×1 |
| Penta | ×1 |

→ **동시 획득**.

### 3.2 족보 내부 — 재료 소모

**같은 족보를 몇 번 만들 수 있는지** 계산할 때만 재료를 소모한다.

예: `11111` — Pair

```text
11  11  →  Pair ×2
```

예: `11111` — Triple

```text
111  →  Triple ×1
```

### 3.3 조합론(CnR) 금지

아래 방식은 **사용하지 않는다**.

```text
11111 → Pair ×10, Triple ×10   ❌
```

플레이어가 직관적으로 이해 가능한 **그리디·재료 소모** 계산만 사용한다.

---

## 4. 동일 숫자 계열 (N-of-a-kind)

### 4.1 족보 목록

| ID (예) | 표시명 | 필요 개수 |
|---------|--------|-----------|
| `pair` | Pair | 2 |
| `triple` | Triple | 3 |
| `quad` | Quad | 4 |
| `penta` | Penta | 5 |
| `hexa` | Hexa | 6 |
| `hepta` | Hepta | 7 |
| `octa` | Octa | 8 |
| `nona` | Nona | 9 |
| `deca` | Deca | 10 |

### 4.2 계산식

어떤 숫자든, 그 숫자의 등장 횟수를 `count`라 할 때:

```text
획득 횟수 = floor(count / n)    (n = 족보별 필요 개수)
```

**숫자별로 계산한 뒤 합산**한다.

### 4.3 예시

`11111` (5개)

| 족보 | 계산 | 획득 |
|------|------|------|
| Pair | floor(5/2) | ×2 |
| Triple | floor(5/3) | ×1 |
| Quad | floor(5/4) | ×1 |
| Penta | floor(5/5) | ×1 |

`111111` (6개)

| 족보 | 획득 |
|------|------|
| Pair | ×3 |
| Triple | ×2 |
| Quad | ×1 |
| Penta | ×1 |
| Hexa | ×1 |

---

## 5. Straight 계열

### 5.1 족보 목록

| ID (예) | 표시명 | 필요 |
|---------|--------|------|
| `straight_5` | 5 Straight | 연속 5개 (예: 1-2-3-4-5) |
| `straight_6` | 6 Straight | 연속 6개 (예: 1-2-3-4-5-6) |

### 5.2 계산 방식

- 주사위 풀에서 **실제로 몇 개의 스트레이트를 만들 수 있는지** 재료 소모식으로 계산.
- **계층 누적:** 상위 스트레이트가 성립하면 하위 스트레이트도 **함께** 획득.

### 5.3 예시

`1122334455`

```text
12345, 12345  →  5 Straight ×2
```

`123456`

```text
5 Straight ×1,  6 Straight ×1
```

`1234523456`

```text
5 Straight ×2,  6 Straight ×1
```

---

## 6. Full House

### 6.1 구성

```text
Triple 1개 + Pair 1개
```

### 6.2 계산 방식

Triple 묶음과 Pair 묶음을 **재료 소모**하여 최대 몇 세트 만들 수 있는지 계산.

### 6.3 예시

`11122`

```text
Full House ×1
```

`1112223344`

```text
Triple: 111, 222
Pair:   33, 44
→ 11133 + 22244
→ Full House ×2
```

---

## 7. Stair 계열

### 7.1 개념

**연속된 숫자**에 대한 **동일 등급 묶음** (Pair Stair, Triple Stair, …).

### 7.2 족보 목록

| 계열 | 족보 |
|------|------|
| Pair Stair | 2 / 3 / 4 / 5 Pair Stair |
| Triple Stair | 2 / 3 Triple Stair |
| Quad Stair | 2 Quad Stair |
| Penta Stair | 2 Penta Stair |

### 7.3 예시

`1122`

```text
2 Pair Stair ×1
```

`112233`

```text
2 Pair Stair ×1,  3 Pair Stair ×1
```

### 7.4 계단 계산 규칙

계단도 **재료 소모식**을 사용한다.

`1122334455` — Pair 묶음: `11 22 33 44 55`

| 족보 | 조합 | 획득 |
|------|------|------|
| 2 Pair Stair | `11-22`, `33-44` | ×2 |
| 3 Pair Stair | `11-22-33` | ×1 |
| 4 Pair Stair | `11-22-33-44` | ×1 |
| 5 Pair Stair | `11-22-33-44-55` | ×1 |

**최종:** `2 Pair Stair ×2`, `3 Pair Stair ×1`, `4 Pair Stair ×1`, `5 Pair Stair ×1`

---

## 8. v1 족보 전체 목록

```text
Pair, Triple, Quad, Penta, Hexa, Hepta, Octa, Nona, Deca
5 Straight, 6 Straight
Full House
2 Pair Stair, 3 Pair Stair, 4 Pair Stair, 5 Pair Stair
2 Triple Stair, 3 Triple Stair
2 Quad Stair, 2 Penta Stair
```

**총 22종.** v1 가치 = 각 1.

---

## 9. 통합 예시

**입력:** `1122334455`

**결과 (동시 획득):**

| 족보 | 획득 |
|------|------|
| Pair | ×5 |
| 5 Straight | ×2 |
| 2 Pair Stair | ×2 |
| 3 Pair Stair | ×1 |
| 4 Pair Stair | ×1 |
| 5 Pair Stair | ×1 |

**Σ(족보 가치)** (v1, 전부 가치 1) = **12**

숫자 합 = 1+1+2+2+3+3+4+4+5+5 = **30**  
→ 점수 = 30 × 12 = **360** (공식 적용 시)

---

## 10. 구현 메모 (Godot)

| 레이어 | 역할 |
|--------|------|
| `HandCalculator` | 입력 `Array[int]` → `Array[HandResult]` (id, count) |
| `ScoreCalculator` | `Σ(숫자)`, `Σ(족보 가치)` → 최종 점수 |
| `hands.json` | id, display_ko, **value** (v1=1) — detect 로직은 코드 |
| `ScorePhasePresenter` | 족보 목록·우측 패널(족보 합) 연출 |

계산 phase(SCORING)에서 `HandCalculator` 호출 → UI는 획득 족보 목록 표시.

---

## 11. v0.1과의 관계

| | v0.1 (현재 구현) | v1 스펙 (본 문서) |
|--|------------------|-------------------|
| 숫자 합 | ✅ | ✅ |
| 족보 | ×1 고정 | 22종 계산 |
| 우측 패널 | `1` placeholder | Σ(족보 가치) |

다음 플레이어블 설계 버전(`v0.2-…`)에서 본 스펙 도입 예정.

---

## 12. 문서 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1 | 2026-06-05 | 족보 계산 v1 — 순차 독립·재료 소모·22종 목록 |
