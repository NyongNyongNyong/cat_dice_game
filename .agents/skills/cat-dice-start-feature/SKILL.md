---
name: cat-dice-start-feature
description: Use when the user asks /start-feature, start feature, create feature branch, or begin new work in the Cat Tower Casino Godot project. Create a feature/* branch from latest main with scripts/start-feature.sh and declare the expected game/ scope before implementation.
---

# Start Feature Branch

Use this skill only when beginning new work in the Cat Tower Casino Godot project. For finishing a feature, use `cat-dice-push`.

## Workflow

1. Require a short slug made of lowercase letters, numbers, and hyphens, such as `dice-roll` or `shop-ui`.
2. Run the repository script from the repo root:

```bash
chmod +x scripts/start-feature.sh 2>/dev/null || true
./scripts/start-feature.sh <short-name>
```

3. If the working tree is not clean, stop and tell the user to commit or stash first.
4. After the branch is created, report the branch name.
5. Infer the likely `game/` paths this slug should touch in one or two short sentences. Do not ask the user to write the path list.
6. **Kanban ticket:** Follow `.cursor/rules/kanban-tickets.mdc`. Find or create `docs/board` card for this slug; set column to `speccing` (docs-first) or `doing` (implementation). Do not ask the user to create the card.
7. For later implementation on this branch, keep edits within the inferred feature scope unless the user explicitly expands it.

## Never Do

- Do not finish or merge the feature here.
- Do not create or use a `develop` branch.
- Do not change `git config`.
