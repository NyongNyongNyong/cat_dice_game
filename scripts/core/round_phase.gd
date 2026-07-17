class_name RoundPhase

enum Phase {
	IDLE,
	ROLLING,
	## 점수 연출 후 — 다음 전체 굴림 또는 상점(층 이동) 대기. (구 REROLL_READY)
	READY,
	SCORING,
	RESOLVED,
}
