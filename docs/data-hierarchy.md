# 게임 정의 데이터 계층

구현: [`data/`](../data/) (`res://data/`).  
기획: [gdd-cat-tower-casino.md](gdd-cat-tower-casino.md) · 설계: [design/v0.1-initial-playable.md](design/v0.1-initial-playable.md) · 족보: [design/systems/hand-scoring-v2.md](design/systems/hand-scoring-v2.md)

## 포함 (풀 게임 데이터 — v0.1 미사용)

```
data/registry.json
core/       symbols, effects
dice/       dice_defs, starter_loadout
scoring/    score_rules, hands (가치 — hand-scoring-v2 스펙)
economy/    chip_brackets
casino/     rules, floors, run_default
items/      relics, consumables, shop_pools
```

## 제외 (GDD §11 미정)

- `Status` / CurseDef · BuffDef
- `Meta` / UnlockDef
- `TurnRules` (리롤·잠금)
- 보스 층·다층 런 (현재 `run_default`는 floor_01만)

## 런타임 (정의 아님 — Godot 구현 시)

- `RunState`, `FloorState`, `RoundState` — `user://` 세이브는 추후
