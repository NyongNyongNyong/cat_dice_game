# 게임 정의 데이터 (MVP)

`res://data/` — GDD v0.1 **정적 카탈로그**. DB 없음.

## 폴더

| 경로 | 내용 |
|------|------|
| `core/` | 문양·효과 원자 |
| `dice/` | 주사위 정의·시작 편성 |
| `scoring/` | 점수 공식·족보 (족보는 임시) |
| `economy/` | 칩 구간 (Push Your Luck) |
| `casino/` | 층·규칙·런 순서 |
| `items/` | 유물·소비·상점 풀 |

## id 규칙

- 영소문자 `snake_case`
- 다른 JSON에서는 `id` 문자열로 참조

## GDD 미정

- 족보·문양 확정 전: `hands.json` / `symbols.json`는 **임시**
- `TurnRules`, `Status`, `Meta` — 폴더 없음

## 로드 (Godot 예정)

```gdscript
# 예: load JSON from res://data/scoring/hands.json
```

`registry.json`에 카탈로그 경로 목록.
