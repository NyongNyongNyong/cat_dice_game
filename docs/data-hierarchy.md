# 게임 정의 데이터 계층

구현: [`game/data/`](../game/data/) (`res://data/`). GDD: [gdd-cat-tower-casino.md](gdd-cat-tower-casino.md).

## 포함 (MVP)

```
game/data/registry.json
core/       symbols, effects
dice/       dice_defs, starter_loadout
scoring/    score_rules, hands (임시)
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
