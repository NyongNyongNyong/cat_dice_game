# 캣타워 카지노 — Agent 지침

Godot 주사위 로그라이크.

## 저장소 레이아웃

```text
docs/              # GDD — res 밖
scripts/           # git 셸 (Godot 아님)
game/              # Godot 루트 (project.godot)
  data/            # res://data/ JSON 카탈로그
  scenes/game|ui|dice/
  scripts/autoload|core|ui|dice/
  resources/dice|items/
  assets/images|sounds/
```

- **씬·스크립트·에셋**은 `game/` 안만. `docs/`, repo `scripts/*.sh`는 res 밖.
- 로직 → `scripts/**/*.gd` · UI 배치 → `scenes/**` · 정의 JSON → `game/data/`

## 기획

- `docs/gdd-cat-tower-casino.md`만 게임 정의. §11 미정은 임의 구현 금지.

## Git

| `/start-feature` | 시작 | **`/push`** | 완료 |
| `/merge-feature` | 머지만 (예외) |

원격 main 갱신 시 push **중단** → `git merge main` → 재실행. git은 슬래시·요청 시만.

## Feature 범위

`feature/<slug>` — 해당 피쳐 파일만. 기획은 GDD만.

**Agent:** 수정 전에 스스로 `game/...` 경로 목록을 짧게 쓰고, 그 안에서만 작업 (사용자에게 “경로 적어줘” 요구하지 않음).

## Godot

- 4.x, `game/project.godot`
- 같은 `.tscn` 동시 수정 금지

## 점수 (GDD §9)

10개 굴림 → `Σ(숫자) × Σ(족보 가치)`.

Rules: `.cursor/rules/*.mdc` · README: 저장소 구조·슬래시
