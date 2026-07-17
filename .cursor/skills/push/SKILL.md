---
name: push
description: Default end-of-feature command. Commit with generated message, stop if origin/main updated, else merge to main. Use for /push when finishing feature work.
disable-model-invocation: true
---

# Push (feature 완료 → main) — **기본 종료 명령**

**언제:** 피쳐 개발이 **끝났을 때** (거의 항상 이것만 사용).  
**브랜치 시작:** `./scripts/start-feature.sh <slug>` (또는 `git checkout -b feature/<slug>`).

`feature/*`에서 **커밋 → origin/main 신규 여부 확인 → 없으면 main merge & push**.  
`origin/main`에 새 커밋이 pull 되면 **머지하지 않고 중단**(exit 2).

## 명령

```
/push
/push -y          # 머지 후 feature 브랜치 삭제
```

## 절차 (순서 고정)

### 1. 브랜치·상태·범위

```bash
git branch --show-current
git status
git diff
git diff --staged
git diff --stat
```

- `feature/*`가 아니면 중단하고 `scripts/start-feature.sh` 안내.
- 변경 없고 이미 커밋만 남은 경우 → `-m` 없이 스크립트 실행 가능.
- `git diff --stat`이 이번 feature slug·요청과 안 맞으면: **에이전트가** 범위 이탈로 경고하고, 분리·재브랜치 제안 (`feature-scope` rule). 사용자에게 경로 목록 작성을 요구하지 않음.

### 2. 문서·코드 정합성 (필수 — 스크립트 실행 전)

브랜치명에서 slug 추출: `feature/<slug>` → `docs/design/systems/<slug>.md`, `docs/design/tasks/<slug>-tasks.md`를 읽고 `git diff`·`git diff --stat`과 대조한다. **불일치 시 push 중단** — 스펙·Task·코드 중 맞춘 뒤 재시도.

**체크리스트:**

| # | 확인 | 불일치 시 |
|---|------|-----------|
| 1 | 시스템 스펙 존재·이번 feature와 동일 slug | 스펙 없으면 생성 또는 slug 확인 |
| 2 | Acceptance Criteria ↔ 실제 구현 (동작·표시·조건) | 스펙 또는 코드 수정 |
| 3 | Task 완료 조건·수정 예상 파일 ↔ `git diff --stat` | Task 또는 diff 정리 |
| 4 | 코드 변경이 스펙·Task에 **근거** 있음 (스펙 없는 기능 없음) | 스펙 먼저 갱신 |
| 5 | **수정 금지** 미변경: `hand-scoring-v2.md` 족보 규칙, 점수 공식, 리롤 비용·횟수 (이 feature 스펙에 명시된 범위 외) | 별도 feature로 분리·되돌림 |
| 6 | 스펙·Task 변경 시 `## 변경 이력` 한 줄 추가 (`docs-and-plans` rule) | 이력 추가 |
| 7 | **칸반 티켓** (`kanban-tickets` rule): slug 카드 찾아/만들고 `column`=`review`, MD 이력·`cards.json` 갱신 후 **이 커밋에 포함** | 티켓 누락 시 중단하고 갱신 |

**출력 (응답에 포함, 통과 전 스크립트 실행 금지):**

```markdown
### Push 전 정합성
- slug: <slug>
- 스펙: docs/design/systems/<slug>.md — (OK / 이슈)
- Task: docs/design/tasks/<slug>-tasks.md — (OK / 없음 / 이슈)
- AC ↔ 구현: (OK / 이슈 요약)
- diff 범위: (OK / 이슈)
- 수정 금지 파일: (미변경 / 이슈)
- 티켓: <id> → review (OK / 생성함 / 이슈)
```

**통과:** 위 항목 모두 OK → Step 3 진행.  
**실패:** 이슈 목록 보고 후 중단. 사용자에게 수정·재-Audit 안내.

### 3. 커밋 메시지 작성

미커밋 변경이 있으면 diff 기준으로 **한 줄** 메시지 생성 (티켓 `cards.json`·`cards/*.md` 변경 포함):

- 접두: `feat:`, `fix:`, `docs:`, `godot:` 중 하나
- 영문 짧은 설명 (저장소 관례)
- 예: `feat: add dice roll scene skeleton`

### 4. 스크립트 실행

```bash
chmod +x scripts/push-feature.sh scripts/merge-feature.sh 2>/dev/null || true
./scripts/push-feature.sh -m "feat: short description"
# 삭제까지: ./scripts/push-feature.sh -m "..." -y
```

### 5. exit 2 (STOP)일 때

스크립트가 main을 pull 한 뒤 멈춘 것. **force push 금지.**

사용자에게 안내:

1. `git merge main` (현재 feature 브랜치에서; 또는 rebase 합의 시 `git rebase main`)
2. 충돌 해결·Godot 1회 확인
3. 다시 `/push`

### 6. 성공 시

- `main`에 반영·push 완료
- 팀원: `git checkout main && git pull` 한 줄

## 머지 전 (Godot 변경 시)

- Step 2 정합성 통과 후, 관련 씬/플로우·GDD 모순 없는지 짧게 확인 (미완이면 사용자에게 질문)

## 하지 않음

- `git push --force`, `git config` 변경
- STOP 상태에서 main에 feature merge 시도
- GitHub PR 생성 (필수 아님)

## 관련

- 브랜치 시작: `./scripts/start-feature.sh <slug>`
- 이미 커밋됨·머지만: `./scripts/merge-feature.sh` (스크립트 직접 실행)
