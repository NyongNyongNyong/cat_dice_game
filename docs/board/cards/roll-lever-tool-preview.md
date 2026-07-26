# RollLever 에디터 미리보기 (@tool)

> `@export`로 노출한 레버 색·치수가 에디터에서도 보이게 한다.

## 배경

`ui-editor-friendly`에서 `RollLever` 색·트랙·노브 값을 `@export`로 인스펙터에 노출했다. 전부 `_draw()`라 Theme가 먹지 않고, `@tool`이 아니라서 **실행 전 미리보기가 안 된다.** 값을 바꾸고 플레이해야만 확인 가능하다.

## 후보 방향

- `roll_lever.gd`에 `@tool` + 에디터에서 `queue_redraw`
- 또는 자식 Control/Texture로 그려 Theme·씬 편집 가능하게 전환 (더 큼)

## 완료 조건

- [ ] 인스펙터에서 Appearance/Layout을 바꾸면 에디터 뷰포트에 반영된다
- [ ] 런타임 레버 동작(스톱·배속)은 그대로다
