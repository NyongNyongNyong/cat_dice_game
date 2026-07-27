# UI presenter 죽은 코드 정리

> 호출되지 않는 roll/score presenter API와 미연결 시그널을 정리한다.

## 대상 (ui-editor-friendly 조사 시점)

| 위치 | 조치 |
|---|---|
| `ScorePhasePresenter.setup()` 6번째 인자 `active_hands_presenter` | 제거. 활성 족보 UI는 `run_scene` → `ActiveHandsPresenter`만 사용 |
| `RollPhasePresenter.play()` · `play_reroll()` | 제거 (`play_roll`만 유지). `setup`은 `dice_row`만 |
| `presentation_finished` (roll/score presenter) | 제거 (emit만, 연결처 없음) |
| `ActiveHandsPresenter.show_summaries` | no-op 제거 |
| `ScorePhasePresenter.clear_active_hands` · `_hand_steps_seen` | 미연결 히스토리 경로 제거 |

## 완료 조건

- [x] 미사용 public API·시그널이 제거되거나 “예약”으로 문서화됐다
- [x] headless 스펙·씬 부팅이 통과한다

## 구현

- 2026-07-27 `feature/ui-dead-code-cleanup` — 코드·`dice-roll-presentation.md` 반영
- 2026-07-27 feature/ui-dead-code-cleanup → main (검증 대기)
