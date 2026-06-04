---
name: start-feature
description: Creates feature/* from latest main. Use for /start-feature when beginning new work—not when finishing (use /push).
disable-model-invocation: true
---

# Start Feature Branch

**언제:** 새 기능·작업을 **시작**할 때만. 피쳐 완료·main 반영은 **`/push`**.

## 명령

```
/start-feature dice-roll    → feature/dice-roll
/start-feature shop-ui
```

## 실행

```bash
chmod +x scripts/start-feature.sh 2>/dev/null || true
./scripts/start-feature.sh <short-name>
```

- slug: 영소문자·숫자·하이픈 (`dice-roll`, `shop-ui`)
- working tree 깨끗해야 함 — 아니면 commit/stash 안내.

## 브랜치 생성 후 (에이전트)

1. 스크립트 실행 결과 확인.
2. 사용자에게: 브랜치명·**이 slug에서 다룰 예상 `game/` 경로**를 에이전트가 추론해 1~2문장으로 알림 (사용자가 경로를 작성할 필요 없음).
3. 이후 이 브랜치에서의 모든 구현은 `feature-scope` rule — 수정 전 경로 목록을 에이전트가 먼저 적음.

## 이후

해당 scope만 수정하며 개발 → 완료 시 **`/push`**.
