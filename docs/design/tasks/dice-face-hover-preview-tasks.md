# Tasks: dice-face-hover-preview

## 구현

- [x] `reroll_preview_presenter.gd` → `face_preview_presenter.gd` 리네이밍 (`.uid` 유지)
- [x] 노드 `RerollPreviewPresenter` → `FacePreviewPresenter` (`run_scene.tscn`, `shop_scene.tscn`)
- [x] `run_scene.gd` presenter 참조 갱신 + `set_active(true)`
- [x] 보드 칸·트레이 칩 `mouse_entered`/`mouse_exited` 배선
- [x] `_can_hover_dice_faces()` 가드 (레버 정지 + IDLE/READY)
- [x] `shop_scene.gd` presenter 참조 이름 갱신

## 검증 (AC)

- [ ] 플레이 화면에서 보드에 배치된 주사위 Hover → 6면 툴팁 표시
- [ ] 트레이(미배치) 주사위 Hover → 6면 툴팁 표시
- [ ] `mouse_exited` 시 툴팁 숨김
- [ ] 굴림 연출 중(ROLLING/SCORING)·레버 굴림 중에는 툴팁 비표시
- [ ] 잠금 칸·빈 칸에는 툴팁 비표시
- [ ] 상점 화면 Hover 기존 동작 유지 (리네이밍 후 회귀 없음)
- [x] Headless 씬 로드 통과 — `godot --headless --path . --quit-after 2` EXIT 0, 오류 없음 (리네이밍 후 uid 캐시 재임포트로 stale 참조 해소)

> 나머지 검증(hover 표시 동작)은 에디터 플레이로 확인 필요. lint/참조 정합성·씬 로드는 통과.
