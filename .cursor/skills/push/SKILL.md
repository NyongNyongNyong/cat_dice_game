---
name: push
description: Default end-of-feature command. Commit with generated message, stop if origin/main updated, else merge to main. Use for /push—not /merge-feature unless already committed.
disable-model-invocation: true
---

# Push (feature 완료 → main) — **기본 종료 명령**

**언제:** 피쳐 개발이 **끝났을 때** (거의 항상 이것만 사용).  
**안 쓸 때:** 브랜치 시작 → `/start-feature` · 이미 커밋만 끝·머지만 → `/merge-feature`(예외).

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

### 2. 커밋 메시지 작성

미커밋 변경이 있으면 diff 기준으로 **한 줄** 메시지 생성:

- 접두: `feat:`, `fix:`, `docs:`, `godot:` 중 하나
- 영문 짧은 설명 (저장소 관례)
- 예: `feat: add dice roll scene skeleton`

### 3. 스크립트 실행

```bash
chmod +x scripts/push-feature.sh scripts/merge-feature.sh 2>/dev/null || true
./scripts/push-feature.sh -m "feat: short description"
# 삭제까지: ./scripts/push-feature.sh -m "..." -y
```

### 4. exit 2 (STOP)일 때

스크립트가 main을 pull 한 뒤 멈춘 것. **force push 금지.**

사용자에게 안내:

1. `git merge main` (현재 feature 브랜치에서; 또는 rebase 합의 시 `git rebase main`)
2. 충돌 해결·Godot 1회 확인
3. 다시 `/push`

### 5. 성공 시

- `main`에 반영·push 완료
- 팀원: `git checkout main && git pull` 한 줄

## 머지 전 (Godot 변경 시)

- 관련 씬/플로우·GDD 모순 없는지 짧게 확인 (미완이면 사용자에게 질문)

## 하지 않음

- `git push --force`, `git config` 변경
- STOP 상태에서 main에 feature merge 시도
- GitHub PR 생성 (필수 아님)

## 관련

- 브랜치만 시작: `/start-feature`
- 이미 커밋됨·머지만: `./scripts/merge-feature.sh`
