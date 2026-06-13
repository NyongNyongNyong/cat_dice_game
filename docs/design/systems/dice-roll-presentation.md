# Dice Roll Presentation

> 문서 유형: 구현 설계 메모  
> 관련 코드: `game/scripts/ui/roll_phase_presenter.gd`, `game/scripts/ui/run_scene.gd`  
> 상태: v0.1 구현 메모

## 목적

주사위 굴림 연출은 점수 계산/굴림 결과 확정과 분리한다.

`RoundController`가 실제 결과(`dice_faces`, `dice_values`)를 먼저 확정하고, `RollPhasePresenter`는 그 결과를 화면에 보여주는 역할만 맡는다. 따라서 이후 3D 주사위, 물리 기반 던지기, 사운드/카메라 연출 등으로 교체해도 core 계산 로직을 바꾸지 않는다.

## 현재 v0.1 연출

현재 구현은 각 주사위 슬롯이 자신의 후보 면들을 짧은 간격으로 랜덤 표시하다가 최종 면으로 멈추는 방식이다.

- 전체 굴림: 모든 주사위 슬롯을 동시에 순환 표시한다.
- 단일 리롤: 선택된 주사위 슬롯만 순환 표시한다.
- 마지막에는 반드시 확정된 `final_faces[index]`와 `final_values[index]`를 `Dice.set_face()`로 표시한다.

## 교체 계약

새 굴림 연출 구현체는 아래 메서드 계약을 유지한다.

```gdscript
func set_dice_views(dice_views: Array[Control]) -> void

func play_roll(
	final_faces: Array,
	final_values: Array[int],
	candidate_faces_by_die: Array,
) -> void

func play_reroll(
	dice_index: int,
	final_faces: Array,
	final_values: Array[int],
	candidate_faces_by_die: Array,
) -> void
```

`run_scene.gd`는 이 계약만 호출한다.

```gdscript
_roll_presenter.set_dice_views(_dice_views)

await _roll_presenter.play_roll(
	_round.dice_faces,
	values,
	_get_roll_face_candidates()
)

await _roll_presenter.play_reroll(
	_round.last_rerolled_die_index,
	_round.dice_faces,
	values,
	_get_roll_face_candidates()
)
```

## 교체 방법

### 1. 기존 presenter 내부 구현 교체

가장 단순한 방법이다. `roll_phase_presenter.gd` 안의 `play_roll()` / `play_reroll()` 내부만 바꾼다.

적합한 예:

- 2D 흔들림
- 회전/스케일 강조
- 사운드 추가
- 슬롯별 delay 또는 easing 조정

### 2. 새 presenter 스크립트로 교체

복잡한 연출은 새 스크립트로 분리한다.

예:

```text
game/scripts/ui/roll_presenters/physics_roll_presenter.gd
game/scripts/ui/roll_presenters/three_d_roll_presenter.gd
```

새 스크립트가 같은 public method를 제공하면 `run_scene.tscn`의 `RollPhasePresenter` 노드 script만 바꿔도 된다.

### 3. 3D/overlay 연출로 확장

`play_roll()` 안에서 임시 overlay나 3D scene을 띄우고, 연출이 끝나면 최종 결과를 기존 dice view에 반영한다.

핵심 규칙:

- 최종 결과는 presenter가 새로 계산하지 않는다.
- presenter는 전달받은 `final_faces`, `final_values`를 최종 표시한다.
- `await play_roll()` / `await play_reroll()`이 끝난 뒤에는 특수면 이펙트와 점수 연출이 이어질 수 있어야 한다.

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-14 | 굴림 연출 교체 계약과 v0.1 랜덤 면 순환 방식 기록 |
