---
name: merge-feature
description: Merge only, no commit step. Use /merge-feature only when working tree is clean; prefer /push for feature completion.
disable-model-invocation: true
---

# Merge Feature → Main — **예외용 (머지만)**

**언제:** 변경사항이 **이미 모두 커밋**된 상태에서 main merge + push만 할 때.  
**기본은 `/push`** (미커밋 포함·커밋 메시지 자동).

PR 없이 `feature/*` → `main` → `origin` push. **사용자가 머지·푸시를 요청했을 때만** 실행한다.

## 명령

```
/merge-feature              # 현재 브랜치가 feature/* 일 때
/merge-feature feature/foo  # 브랜치 지정
/merge-feature -y           # 머지 후 feature 브랜치 삭제
```

## 실행 (필수)

저장소 루트에서:

```bash
chmod +x scripts/merge-feature.sh 2>/dev/null || true
./scripts/merge-feature.sh [options] [feature/branch]
```

- 스크립트가 실패하면 **임의로** `git push --force` 하지 않는다.
- **exit 2**: `origin/main`에 새 커밋이 pull 됨 → main에 merge 하지 않음. feature에서 `git merge main` 후 재실행.
- uncommitted changes → `/push` 또는 `push-feature.sh -m` 사용. 여기서는 commit 없이 머지만.

## 머지 전 (Godot 변경이 있으면 안내)

- [ ] 관련 씬/플로우 1회 확인 (사용자 또는 짧게 질문)
- [ ] GDD와 모순 없음

## 머지 후

- 팀원에게: `git checkout main && git pull` 안내 한 줄.
- `-y` 없이 끝났으면 feature 브랜치 삭제 여부를 물을 수 있음 → 원하면 `./scripts/merge-feature.sh -y feature/...` 재실행 안내.

## 하지 않음

- `develop` 브랜치 생성·사용
- GitHub PR 생성 (필수 아님)
- `git config` 변경
