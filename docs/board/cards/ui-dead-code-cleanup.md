# UI presenter 죽은 코드 정리

> 호출되지 않는 roll/score presenter API와 미연결 시그널을 정리한다.

## 대상 (ui-editor-friendly 조사 시점)

| 위치 | 상태 |
|---|---|
| `ScorePhasePresenter.setup()` 6번째 인자 `active_hands_presenter` | `run_scene`이 넘기지 않음 → 내부 히스토리 연동 no-op |
| `RollPhasePresenter.play()` · `play_reroll()` | 미사용 (`play_roll`만 사용) |
| `presentation_finished` (roll/score presenter) | emit만 하고 연결처 없음 |

동작 변화 위험은 낮지만, 다음 UI 리팩터 전에 정리하면 읽기 부담이 줄어든다. 삭제 전에 호출 그래프를 한 번 더 확인한다.

## 완료 조건

- [ ] 미사용 public API·시그널이 제거되거나 “예약”으로 문서화됐다
- [ ] headless 스펙·씬 부팅이 통과한다
