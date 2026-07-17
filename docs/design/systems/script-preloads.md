# 시스템 스펙: script-preloads (캐시 비의존 스크립트)

> **slug:** `script-preloads`  
> **상태:** 구현 중 (규칙·문서)  
> **목적:** AI/에이전트가 `.godot` 로컬 캐시에만 의존하는 코드를 만들지 않게 한다.

---

## 문제

`.godot/` 는 **gitignore** — 팀원·CI·다른 PC에는 없다.  
에디터/에이전트 머신에만 생긴 캐시(글로벌 `class_name` 레지스트리, import 캐시 등)를 전제로 짜면:

- 다른 사람 clone 후 실행·헤드리스 테스트 실패
- “내 PC에선 되는데” 재현 불가

## 규칙 (AC)

| # | 조건 |
|---|------|
| 1 | 다른 스크립트를 **런타임에 쓸 때** 반드시 `const X := preload("res://...")` (또는 `load`) — 경로 명시 |
| 2 | `.godot/` 아래 파일을 **커밋·수정·의존하지 않음** (로그 출력만 예외적으로 생성 가능) |
| 3 | 새 `.gd` / `.tscn` / `.tres` 추가 시 짝 `.uid`를 **저장소에 포함** (에디터·Godot가 생성한 것) |
| 4 | 씬 ExtResource는 가능하면 `path="res://..."` 유지; uid만 있고 path가 깨진 참조 금지 |
| 5 | 변경 후 headless로 스크립트/씬 로드 확인 (`--log-file` repo 내부) |

`class_name` 자체는 허용. 다만 **다른 파일에서 그 타입을 쓰려면** 해당 파일에 `preload`로 스크립트를 끌어오는 것을 기본으로 한다.  
타입 힌트만 `HandEvaluation`처럼 쓰고 preload가 없으면, 캐시 재생성 전 환경에서 취약해질 수 있다.

## 비범위

- `.godot` 폴더를 저장소에 넣지 않음
- Godot 엔진 import 파이프라인 자체를 재구현하지 않음

## 구현 위치

| 항목 | 경로 |
|------|------|
| Agent 규칙 | `.cursor/rules/godot-development.mdc` · `AGENTS.md` |
| 티켓 | `docs/board/cards/script-preloads.md` |

## Acceptance Criteria

- [x] 위 규칙이 Agent 문서에 명시됨
- [x] 티켓 description이 “캐시 비의존”으로 명확함
- [ ] (후속) 기존 코드에 preload 누락이 있으면 해당 feature에서 수정

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | 의도 확정 — `.godot` 캐시 비의존 preload 규칙 |
