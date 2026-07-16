# 백로그 칸반 (GitHub Pages)

> **문서 유형:** 문서·웹 도구 스펙  
> **기획 참조:** [backlog.md](../../backlog.md)  
> **상태:** v1  
> **구현:** `docs/board/` · `docs/index.html`

---

## 목적

`docs/backlog.md`는 가독성이 떨어져, Issues/Projects 없이 **정적 칸반**으로 백로그를 본다.

| 원칙 | 설명 |
|------|------|
| Issues 없음 | GitHub Projects·이슈 연동 안 함 |
| 데이터 | `docs/board/cards.json` |
| 배포 | GitHub Pages, branch `main`, folder `/docs` |
| 팀 공유 | 드래그 결과는 localStorage 임시 → JSON 커밋으로 공유 |

---

## 동작 조건

### 표시

- 열 4개: 할 일 / 진행 중 / 완료 / 나중에
- 카드: 제목, 본문(선택), 태그
- `cards.json`을 fetch로 로드

### 드래그

- 카드를 다른 열로 드롭하면 `column` 갱신
- 변경은 **브라우저 localStorage**에만 저장
- **JSON 복사** / **cards.json 저장**으로 파일 내보내기 → 커밋하면 팀 반영
- **저장소 기준으로 되돌리기** → localStorage 삭제 후 원격 JSON 재로드

### Pages

- 문서 홈: `/` → `docs/index.html`
- 칸반: `/board/` → `docs/board/index.html`

---

## 표시 정보

| 위치 | 내용 |
|------|------|
| 헤더 | 제목, 메타(저장소/임시), 버튼 |
| 힌트 | 드래그·커밋 안내 |
| 열 | 제목 + 카드 수 |
| 카드 | title / body / tags |

---

## 예외 조건

| 상황 | 동작 |
|------|------|
| `cards.json` 로드 실패 | 보드에 오류 문구 |
| `file://`로 열기 | fetch 실패 가능 → `docs`에서 로컬 HTTP 서버 권장 |
| backlog.md와 cards.json 불일치 | **보드 정본은 cards.json**; backlog는 메모·이력 |

---

## 영향받는 시스템

- Godot 게임 코드: **미변경**
- `hand-scoring-v2` · 점수·리롤: **미변경**

---

## Acceptance Criteria

- [x] `docs/board/`에 칸반 UI + `cards.json`이 있다.
- [x] 카드를 열 사이로 드래그할 수 있다.
- [x] JSON 복사·다운로드로 `cards.json`을 내보낼 수 있다.
- [x] localStorage 임시 저장을 저장소 JSON으로 되돌릴 수 있다.
- [x] `docs/index.html`이 칸반·문서 링크를 제공한다.
- [x] README·backlog에 칸반 링크가 있다.
- [ ] GitHub Pages(`/docs`)는 저장소 Settings에서 한 번 켠다 (배포 설정은 수동).

---

## 구현 메모

| 항목 | 경로 |
|------|------|
| 칸반 | `docs/board/index.html` · `board.css` · `board.js` |
| 데이터 | `docs/board/cards.json` |
| 사용법 | `docs/board/README.md` |
| 문서 홈 | `docs/index.html` |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | v1 — Pages 칸반, cards.json, Issues 없이 드래그·내보내기 |
