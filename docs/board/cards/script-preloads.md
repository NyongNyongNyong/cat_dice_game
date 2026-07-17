# feature/script-preloads

> 에이전트가 `.godot` 로컬 캐시에만 의존하는 코드를 만들지 않게 한다. 다른 클론·팀원이 실행 가능해야 함.

## 문제

`.godot/` 는 gitignore. 캐시 전제 코딩 → “내 PC만 됨”.

## 규칙 요약

1. 타 스크립트 = `preload("res://...")`
2. `.godot/` 커밋·의존 금지 (로그 파일 출력만 예외)
3. 새 리소스 `.uid` 커밋
4. 변경 후 headless 검증

## 구현

- 2026-07-17 `feature/script-preloads` → main (검증 대기)
- 스펙·Agent 규칙 반영 (`script-preloads.md`, `godot-development.mdc`, `AGENTS.md`)
- 기존 코드 전수 preload 감사는 후속

스펙: `docs/design/systems/script-preloads.md`
