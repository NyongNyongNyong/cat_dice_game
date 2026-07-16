# 백로그 칸반 (GitHub Pages)

Issues / Projects 없이 백로그를 칸반으로 봅니다.

## URL (Pages 켜면)

- 문서 홈: `https://NyongNyongNyong.github.io/cat_dice_game/`
- 칸반: `https://NyongNyongNyong.github.io/cat_dice_game/board/`

## Pages 설정 (한 번만)

1. 저장소 **Settings → Pages**
2. **Source**: Deploy from a branch
3. **Branch**: `main` / 폴더 **`/docs`**
4. Save

## 데이터 갱신

1. 칸반에서 카드 드래그
2. **JSON 복사** 또는 **cards.json 저장**
3. 로컬 `docs/board/cards.json` 덮어쓰고 커밋

브라우저 임시 저장(localStorage)은 본인 PC에만 남습니다. 팀 공유는 반드시 `cards.json` 커밋.

## 파일

| 파일 | 역할 |
|------|------|
| `cards.json` | 카드·열 정본 (보드용) |
| `index.html` / `board.css` / `board.js` | UI |

`docs/backlog.md`는 메모·이력용으로 유지. 보드와 어긋나면 `cards.json`을 우선하고 backlog를 맞추면 됩니다.
