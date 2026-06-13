# Tasks: shop-scene

## 구현

- [x] `shop_scene.tscn` + `shop_scene.gd` (Full Rect, ScrollContainer)
- [x] `GameFlow` autoload + `main.gd` 씬 스왑
- [x] `run_scene` 상점 패널 제거, `GameFlow.show_shop()` 연동
- [x] `RunManager.enter_shop()` / `is_run_started()` — 씬 복귀 시 런 유지
- [x] `dice_shop_presenter.gd` — 패널 visibility 제거, `refresh()` API

## 검증

- [ ] 에디터: Next Floor → 상점 전환, 교체, 다음 층 → 플레이 복귀
- [ ] 작은 해상도에서 ScrollContainer 동작 확인
