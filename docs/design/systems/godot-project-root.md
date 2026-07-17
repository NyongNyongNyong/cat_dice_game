# 시스템 스펙: godot-project-root

> **slug:** `godot-project-root`  
> **상태:** 구현 완료 (검증 대기)  
> **목적:** Godot 프로젝트 루트와 Cursor 작업공간 루트를 일치시킨다.

---

## 배경

기존에 Godot는 `game/` 하위에 있고 Cursor는 저장소 루트를 열어, 경로·LSP·headless 실행이 어긋나기 쉬웠다.

## 목표 구조

```text
repository-root/
├─ project.godot
├─ scenes/ · scripts/ · data/ · resources/ · assets/
├─ tools/          # Git 셸 (구 repo scripts/*.sh)
├─ docs/ · .cursor/ · AGENTS.md · README.md
```

## 규칙 (AC)

| # | 조건 |
|---|------|
| 1 | 저장소 루트에 `project.godot` 존재, `game/` 폴더 없음 |
| 2 | Godot `scripts/`와 충돌하지 않도록 Git 셸은 `tools/` |
| 3 | `.godot/`는 gitignore — 이동·커밋하지 않음 |
| 4 | `res://` 경로는 파일시스템 절대경로로 바꾸지 않음 (`scenes/game/` 씬 폴더명 유지) |
| 5 | 문서·규칙·스킬의 `--path game` / `game/...` 참조를 새 구조에 맞게 갱신 |
| 6 | headless `--path .`로 부팅·스펙 테스트 가능 |

## 비범위

- 게임 로직·리소스 내용 변경
- 족보/점수 공식 변경

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | 레이아웃 이동 스펙·AC |
