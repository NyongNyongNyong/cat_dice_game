# feature/godot-project-root

> Godot 프로젝트를 `game/`에서 저장소 루트로 이동. Cursor 작업공간과 Godot 루트 일치.

## 구현

- 2026-07-17 `feature/godot-project-root` → main (검증 대기)
- `game/` 내용 → 저장소 루트 (`project.godot`, `scenes/`, `scripts/`, …)
- Git 셸 `scripts/*.sh` → `tools/`
- `.godot/` 캐시는 이동·커밋하지 않음
- 문서·규칙·스킬의 `game/`·`--path game`·`./scripts/*.sh` 참조 갱신

## 검증

- [x] 루트에 `project.godot`
- [x] headless `--path .` 부팅
- [x] `board_spec_test.gd` PASS (경로 fallback 경고만, 로드 OK)

스펙: `docs/design/systems/godot-project-root.md`
