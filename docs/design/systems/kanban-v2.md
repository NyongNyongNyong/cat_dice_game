# 칸반 v2 (7열 · 카드↔MD)

> **문서 유형:** 문서·웹 도구 스펙  
> **관련:** [docs-kanban-board.md](docs-kanban-board.md) (v1)  
> **상태:** v2  
> **구현:** `docs/board/`

---

## 목적

백로그를 **7열 워크플로**로 보고, 각 카드는 **MD 파일 1개**와 대응한다.  
클릭 시 팝업으로 상세를 읽고, 드래그로 열을 옮긴다.

---

## 열 정의

| id | 제목 | 의미 |
|----|------|------|
| `ideas` | 아이디어 / 백로그 | 구현 미확정 후보 |
| `speccing` | 스펙 작성 중 | `/feature`로 스펙·Task 작성 중 |
| `ready` | 구현 대기 | 스펙 확정, 바로 코딩 가능 |
| `doing` | 구현 중 | 실제 작업 중 (인당 1~2 권장) |
| `review` | 검증 대기 | 구현 끝, 플레이·코드 검증 |
| `fix` | 수정 필요 | 검증에서 문제 발견 → 수정 후 `doing`→`review` |
| `done` | 완료 | 구현+검증 통과 |

---

## 데이터 모델

### `cards.json` (인덱스)

```json
{
  "id": "luck-sources",
  "title": "행운 변동 소스 확장",
  "description": "한 줄 요약",
  "column": "doing",
  "file": "cards/luck-sources.md",
  "tags": ["행운"]
}
```

### `cards/<id>.md` (본문)

```markdown
# 제목

> description (한 줄)

## 상세
...
```

- **1카드 = 1 MD** (`file` 경로)
- 보드 카드 UI: `title` + `description`
- 팝업: MD 전문 렌더

---

## 동작

| 입력 | 동작 |
|------|------|
| 드래그&드롭 | `column` 변경 → localStorage(v2) 임시 저장 |
| 클릭 / Enter | MD fetch → 모달 상세 |
| JSON 복사·저장 | 열 배치를 `cards.json`으로 내보내기 |
| 저장소로 되돌리기 | localStorage 삭제 |

드래그 직후 클릭은 무시(오픈 방지).

---

## Acceptance Criteria

- [x] 7열이 표시되고 가로 스크롤된다.
- [x] 카드에 title·description이 보인다.
- [x] 드래그로 열을 옮길 수 있다.
- [x] 클릭 시 연결된 MD가 팝업으로 보인다.
- [x] 각 카드에 `cards/<id>.md`가 있다.
- [x] Godot/점수 시스템 미변경.

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-07-17 | v2 — 7열, 카드↔MD, 클릭 팝업 |
