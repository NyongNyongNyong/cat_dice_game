# run_scene HUD 분리

> `run_scene.gd`(~700줄)에서 표시·입력을 분리해 UI 교체·편집을 더 쉽게 한다.

## 배경

`ui-editor-friendly`에서 Unique Name·컨테이너 안전화까지는 했다. 보드 구축·드래그·굴림 루프·연출이 한 파일에 남아 있어, 나중에 HUD만 갈아끼우거나 레이아웃을 크게 바꿀 때 부담이 크다.

## 후보 방향

- `GameHUD`(또는 동등) 씬 + 표시 API (`set_score` 등)
- 보드/트레이 전용 presenter로 드래그·슬롯 관리 분리
- `RoundController` 시그널 연결만 씬 루트에 남기기

대규모 변경이므로 별도 `feature/run-scene-hud-split`로 진행한다. 게임 규칙 파일은 건드리지 않는다.

## 완료 조건

- [ ] 표시·버튼 입력이 HUD(또는 presenter)로 이동했다
- [ ] `run_scene`은 플로우 조율 위주로 줄었다
- [ ] Unique Name / 에디터 편집 규칙은 [ui-editor-friendly.md](../design/systems/ui-editor-friendly.md)를 유지한다
