---
name: cat-dice-push
description: Use when the user asks /push, push, finish this feature, commit and merge, or complete a feature branch in the Cat Tower Casino Godot project. Finish a feature/* branch by inspecting scope, generating a commit message, running scripts/push-feature.sh, and stopping safely if origin/main changed.
---

# Push Feature

Use this skill only in the Cat Tower Casino Godot project when the user wants to finish a feature branch and reflect it on main. Prefer this workflow for feature completion. Use `cat-dice-start-feature` only when beginning a branch. Use `cat-dice-merge-feature` only when everything is already committed and the user wants merge-only.

## Workflow

1. Inspect the branch, status, and scope before acting:

```bash
git branch --show-current
git status
git diff
git diff --staged
git diff --stat
```

2. If the current branch is not `feature/*`, stop and guide the user to start a feature branch with `scripts/start-feature.sh`.
3. If the diff stat does not match the current feature slug or the user's request, warn about scope drift and suggest splitting or rebranching. Do not ask the user to provide a path list.
4. If there are uncommitted changes, generate one short English commit message from the diff. Use one of these prefixes: `feat:`, `fix:`, `docs:`, `godot:`.
5. Run the repository scripts from the repo root:

```bash
chmod +x scripts/push-feature.sh scripts/merge-feature.sh 2>/dev/null || true
./scripts/push-feature.sh -m "feat: short description"
```

If the user requested branch deletion after merge, pass `-y`.

6. If there are no uncommitted changes and commits are already ready, run `scripts/push-feature.sh` without `-m` if the script supports that flow.

## Stop Condition

If the script exits 2 because `origin/main` changed, do not force push and do not merge the feature branch into main. Tell the user to:

1. Merge or rebase main into the current feature branch.
2. Resolve conflicts and verify the affected Godot scene or flow once.
3. Run this workflow again.

## Godot Check

Before merge, if Godot scenes, resources, or gameplay flows changed, briefly confirm the relevant scene or flow and check for GDD contradictions. Ask a short question only when this cannot be inferred.

## Success Message

On success, say that main was updated and pushed, then tell teammates:

```bash
git checkout main && git pull
```

## Never Do

- Do not run `git push --force`.
- Do not change `git config`.
- Do not create or use a `develop` branch.
- Do not create a GitHub PR unless the user explicitly asks.
