---
name: cat-dice-merge-feature
description: Use when the user asks /merge-feature, merge feature, merge-only, or push an already committed feature branch in the Cat Tower Casino Godot project. Merge a clean, already-committed feature/* branch to main with scripts/merge-feature.sh and stop safely if origin/main changed.
---

# Merge Feature

Use this skill only for the exceptional merge-only workflow in the Cat Tower Casino Godot project, when all changes are already committed. For normal feature completion with uncommitted changes, use `cat-dice-push`.

## Workflow

1. Confirm the working tree is clean. If there are uncommitted changes, stop and use `cat-dice-push` instead.
2. Use the current `feature/*` branch unless the user supplied a specific feature branch.
3. Run the repository script from the repo root:

```bash
chmod +x scripts/merge-feature.sh 2>/dev/null || true
./scripts/merge-feature.sh [options] [feature/branch]
```

If the user requested branch deletion after merge, pass `-y`.

## Stop Condition

If the script exits 2 because `origin/main` changed, do not force push and do not merge the feature branch into main. Tell the user to:

1. Merge main into the feature branch.
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
