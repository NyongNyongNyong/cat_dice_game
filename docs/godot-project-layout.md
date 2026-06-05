# Godot 프로젝트 폴더

**엔진:** Godot **4.6.3 stable** ([다운로드](https://godotengine.org/download/archive/4.6.3-stable/))

**정본:** repo의 `game/` 트리. README 저장소 구조와 동일.

## `res://` 매핑

| 경로 | 용도 |
|------|------|
| `res://data/` | JSON 카탈로그 (`registry.json`) |
| `res://scenes/game/` | 런·층·라운드·상점 |
| `res://scenes/ui/` | HUD, 메뉴 |
| `res://scenes/dice/` | 굴림 연출 |
| `res://scripts/autoload/` | DataRegistry, RunManager |
| `res://scripts/core/` | 점수·칩·런 (씬 무관) |
| `res://scripts/ui/` · `res://scripts/dice/` | 도메인 스크립트 |
| `res://resources/dice/` · `items/` | `.tres` (JSON 이전 후) |
| `res://assets/images/` · `sounds/` | 아트·오디오 |

Repo 밖: `docs/`, `scripts/*.sh`, `.cursor/`

## feature → 폴더 (예)

| feature | 주로 |
|---------|------|
| `shop-ui` | `scenes/ui/`, `scenes/game/*shop*`, `scripts/ui/` |
| `dice-roll` | `scenes/dice/`, `scripts/dice/`, `scripts/core/*score*` |

## Autoload (예정)

`scripts/autoload/data_registry.gd` — `res://data/registry.json` 로드

## MVP 다음 파일

- `scenes/game/main.tscn`
- `scripts/autoload/data_registry.gd`
