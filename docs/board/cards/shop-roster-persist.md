# 상점 교체 주사위 다음 층 유지

> 상점에서 보유 주사위를 바꾸면 다음 층에서 원상복구됨 → 교체 결과가 유지되어야 함.

## 상세

- 증상: 상점에서 보유 슬롯을 교체한 뒤 Next Floor로 돌아가면 교체 전 roster로 되돌아감.
- 의심: `advance_floor` / `reset_floor_round` / roster 리셋(`reset_to_starting`) 경로.

## 완료 조건

- [ ] 상점 구매·교체 후 다음 층 run 화면에서 **같은** 보유 주사위가 유지된다.
- [ ] 층 이동만으로 starter loadout으로 되돌리지 않는다.
