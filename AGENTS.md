# 캣타워 카지노 — Agent 지침

Godot 주사위 로그라이크.

## 저장소 레이아웃

```text
docs/              # 기획·설계 — res 밖
  gdd-*.md         # 기획 (비전·방향)
  design/          # 구현 설계 (씬·스크립트·범위)
    systems/       # 시스템 스펙 (족보 계산 등)
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

## 문서

- **기획:** `docs/gdd-cat-tower-casino.md` — 비전·시스템 방향. §11 미정은 임의 구현 금지.
- **설계:** `docs/design/` — 현재 구현 스코프·씬·스크립트. 최신: `v0.1-initial-playable.md`.
- **시스템 스펙:** `docs/design/systems/` — 족보 **v2 정본**: `hand-scoring-v2.md` (`hand_calculator.gd` v2).

## Git · Feature 워크플로

- **`/feature`** → 피드백(평문) → **`/push`**
- 다이어그램: [docs/design/feature-workflow.md](docs/design/feature-workflow.md)

원격 main 갱신 시 push **중단** → `git merge main` → 재실행. git은 슬래시·요청 시만.

## Feature 범위

`feature/<slug>` — 해당 피쳐 파일만. 방향은 GDD, 구현 범위는 설계 문서.

**Agent:** 수정 전에 스스로 `game/...` 경로 목록을 짧게 쓰고, 그 안에서만 작업 (사용자에게 “경로 적어줘” 요구하지 않음).

## Godot

- **4.6.3 stable** 고정 (`game/project.godot`). 4.7 beta·다른 마이너 사용 금지.
- 같은 `.tscn` 동시 수정 금지
- **Headless 테스트 실행:** Godot는 기본 로그를 `user://logs`에 쓰므로 샌드박스 에이전트에서 `Failed to open 'user://logs/...'` 후 크래시할 수 있다. 항상 repo 내부 로그 파일을 지정한다.
  - 권장 형식: `..\Godot_v4.6-stable_mono_win64_console.exe --headless --path game --log-file .godot/agent-headless.log --script res://scripts/core/<test>.gd`
  - 씬 로딩 확인: `..\Godot_v4.6-stable_mono_win64_console.exe --headless --path game --log-file .godot/agent-headless.log --quit-after 1`
  - 실패 원인이 권한이 아니라 스크립트 오류인지 보기 위해, `--log-file` 없이 먼저 실행하지 않는다.

## 점수

- **v0.1 구현:** 숫자 총합만, 우측 족보 ×1 고정.
- **풀 게임 (GDD §9):** `Σ(숫자) × Σ(족보 가치)` — **스펙·코드:** `docs/design/systems/hand-scoring-v2.md`, `hand_calculator.gd`.

Rules: `.cursor/rules/*.mdc` · README: 저장소 구조·슬래시
