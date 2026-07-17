# /feature 예시 — Hover Preview

## 사용자 입력

```
/feature 주사위를 굴린 후에 점수가 계산된 이후, 각 주사위에 마우스 오버 시 이 주사위를 다시 굴린 각각의 경우의 수들에 대해 최고/최저 점수를 팝업으로 띄운다.
```

## Step 1 — 스펙 요약 + slug

주사위 Hover 시 해당 주사위 1개 리롤 시 최고/최저 **점수 변화량**을 표시한다.

- slug: `dice-hover-reroll-preview`
- 브랜치: `feature/dice-hover-reroll-preview`

**중요:** 최고/최저 점수 자체가 아니라 **현재 점수 대비 변화량**을 표시한다.

## Step 2 — 브랜치 생성

```bash
git branch --show-current
git status --porcelain
./tools/start-feature.sh dice-hover-reroll-preview
# → feature/dice-hover-reroll-preview 에서 문서·Task·코드 모두 진행
```

## Step 3 — 관련 문서

| 문서 | 조치 |
|------|------|
| `docs/gdd-cat-tower-casino.md` §4·§9 | 참조만 (방향 확인) |
| `docs/design/systems/hand-scoring-v2.md` | 수정 금지 — 계산기 재사용 |
| `docs/design/systems/dice-hover-reroll-preview.md` | 신규 또는 갱신 |

## Acceptance Criteria

- 점수 계산 이후에만 Hover Preview가 동작한다.
- 각 주사위에 Hover할 수 있다.
- Hover한 주사위 **하나만** 값이 바뀐다고 가정한다.
- 해당 주사위의 가능한 모든 면을 계산한다.
- 현재 점수 대비 **최고 변화량**을 계산한다.
- 현재 점수 대비 **최저 변화량**을 계산한다.
- UI에는 **변화량만** 표시한다.
- 표시 형식은 `▲ +n`, `▼ -n` 또는 이에 준하는 간단한 형식이다.
- 기존 점수 공식은 변경하지 않는다.
- 기존 족보 계산 규칙은 변경하지 않는다.
- 기존 리롤 규칙은 변경하지 않는다.

## Task 예시

`docs/design/tasks/dice-hover-reroll-preview-tasks.md`:

```markdown
# Task: Hover Preview

## Task 1. Hover Preview 계산 로직 추가

**목적:**
- 특정 주사위 하나를 각 면으로 바꿨을 때의 최고/최저 점수 변화량 계산

**수정 예상 파일:**
- `scripts/core/reroll_preview_calculator.gd` (신규)
- `scripts/core/hand_calculator.gd` (호출만)

**수정 금지:**
- `hand-scoring-v2.md` 족보 규칙
- 점수 공식
- 리롤 비용·횟수 규칙

**완료 조건:**
- 현재 점수 대비 `best_delta` / `worst_delta`를 계산할 수 있다.

---

## Task 2. Hover UI 표시

**목적:**
- 주사위 Hover 시 best_delta / worst_delta를 팝업으로 표시

**수정 예상 파일:**
- `scripts/ui/reroll_preview_presenter.gd`
- `scenes/dice/dice.gd`

**완료 조건:**
- Hover 시 `▲ +n`, `▼ -n` 형식으로 표시된다.
```

## Audit 체크리스트 (Hover Preview)

| 항목 | 확인 |
|------|------|
| `feature/dice-hover-reroll-preview`에서 작업 완료 | |
| REROLL_READY phase에서만 동작 | |
| HandCalculator 동일 입력·동일 공식 | |
| 변화량 표시 (절대 점수 아님) | |
| 리롤 규칙·비용 미변경 | |
