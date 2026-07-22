# 시스템 스펙: specs-hub

> **slug:** `specs-hub`  
> **상태:** 구현 완료 (검증 대기)

## 목표

확정된 시스템 스펙을 카테고리별로 모아 GitHub Pages에서 읽기 쉽게 보여 준다.

## 구현

| 경로 | 역할 |
|------|------|
| `docs/specs/index.html` | 허브 UI |
| `docs/specs/catalog.json` | 카테고리·카드 인덱스 |
| `docs/specs/specs.css` · `specs.js` | 스타일·MD 모달 |
| README · `docs/index.html` | 칸반 아래 스펙 |

## Acceptance Criteria

- [x] 카테고리별 카드 목록
- [x] 카드 클릭 시 MD 본문 모달
- [x] Pages URL `/specs/`
- [x] 칸반 링크 바로 아래에 스펙

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-22 | 스펙 허브 Pages 초안 |
