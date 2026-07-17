# Godot 프로젝트 폴더

**엔진:** Godot **4.7 stable** ([다운로드](https://godotengine.org/download/archive/4.7-stable/))

**정본:** 저장소 루트(= Godot 프로젝트). README 저장소 구조와 동일.

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

Godot res 밖: `docs/`, `tools/*.sh`, `.cursor/`

## feature → 폴더 (예)

| feature | 주로 |
|---------|------|
| `shop-ui` | `scenes/ui/`, `scenes/game/*shop*`, `scripts/ui/` |
| `dice-roll` | `scenes/dice/`, `scripts/dice/`, `scripts/core/*score*` |

## Autoload (예정)

`scripts/autoload/data_registry.gd` — `res://data/registry.json` 로드

## v0.1 설계 다음 파일

설계: [design/v0.1-initial-playable.md](design/v0.1-initial-playable.md)

- `scenes/game/main.tscn`
- `scenes/game/run_scene.tscn`
- `scenes/dice/dice.tscn`
- `scripts/autoload/run_manager.gd`
- `scripts/core/round_controller.gd` · `round_phase.gd`
- `scripts/core/hand_calculator.gd` · `hand_step.gd` · `hand_evaluation.gd`
- `scripts/core/score_calculator.gd`
- `scripts/ui/roll_phase_presenter.gd` · `score_phase_presenter.gd`
