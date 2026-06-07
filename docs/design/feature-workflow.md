# Feature 개발 워크플로

> **정본:** Cursor `/feature` 스킬 · `.cursor/rules/feature-scope.mdc`  
> **브랜치:** `feature/<slug>` 에서만 문서·코드 편집 · 완료 시 `/push`

---

## 1. 전체 플로우 (한눈에)

```mermaid
flowchart TB
  subgraph start [시작]
    A["/feature 기능 설명"]
  end

  subgraph feature_branch [feature/slug 브랜치]
    B["Step 1 입력 해석 + slug"]
    C["Step 2 브랜치 생성·체크아웃"]
    D["Step 3~4 스펙 문서"]
    E["Step 5 Task 문서"]
    F["Step 6 코드 구현"]
    G["Step 7 전체 Audit"]
  end

  subgraph review [검토·피드백]
    H["유저 확인"]
    I{"피드백?"}
    J["스펙 → Task/AC → 코드 → 미니 Audit"]
  end

  subgraph finish [완료]
    K["완료 신호 OK / push"]
    L["전체 Audit 재실행"]
    M["/push 커밋 + main merge"]
  end

  A --> B --> C --> D --> E --> F --> G --> H
  H --> I
  I -->|있음| J --> H
  I -->|없음| K --> L --> M
```

피드백은 **별도 스킬 입력 없이** 평문으로 주면 된다 (`feature-scope` rule이 `feature/*` 브랜치에서 자동 적용).

---

## 2. `/feature` 상세 단계

```mermaid
flowchart LR
  S1["1. 입력 해석\n한 문장 + slug"]
  S2["2. 브랜치\nstart-feature.sh"]
  S3["3. 문서 탐색\nGDD·systems·v0.1"]
  S4["4. 스펙 작성\nsystems/slug.md"]
  S5["5. Task\n tasks/slug-tasks.md"]
  S6["6. 구현\ngame/"]
  S7["7. Audit"]

  S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7
```

| Step | 산출물 | 경로 예 |
|------|--------|---------|
| 2 | Git 브랜치 | `feature/dice-hover-reroll-preview` |
| 4 | 시스템 스펙 | `docs/design/systems/<slug>.md` |
| 5 | Task | `docs/design/tasks/<slug>-tasks.md` |
| 6 | Godot 코드·씬 | `game/scripts/`, `game/scenes/` |

**모든 편집(문서·Task·코드)은 Step 2 이후 `feature/<slug>`에서만** 한다.

---

## 3. 피드백 라운드

```mermaid
flowchart TB
  FB["유저 피드백\n평문 OK"]
  SP["1. 스펙 갱신\nsystems/slug.md"]
  TK["2. Task/AC 갱신\ntasks/slug-tasks.md"]
  CD["3. 코드 수정\ngame/"]
  MA["4. 미니 Audit\n응답 말미 3~5줄"]
  CHK{"완료?"}

  FB --> SP --> TK --> CD --> MA --> CHK
  CHK -->|더 수정| FB
  CHK -->|OK / push| FA["전체 Audit"]
```

### 문서 계층 (무엇을 고칠지)

```mermaid
flowchart TB
  FB2["피드백 내용"]
  SYS["systems/slug.md\n동작·표시·계산·AC"]
  TASK["tasks/slug-tasks.md\n완료 조건·파일 목록"]
  V01["v0.1-initial-playable.md\nphase·구현 범위"]
  GDD["gdd-cat-tower-casino.md\n방향·재미 축만"]

  FB2 --> SYS
  FB2 --> TASK
  FB2 -.->|범위·phase 변경| V01
  FB2 -.->|방향 변경| GDD
```

| 변경 유형 | 우선 수정 |
|-----------|-----------|
| 표시 형식, Hover 조건, 계산 방식 | `docs/design/systems/<slug>.md` |
| 완료 조건, 수정 파일 | `docs/design/tasks/<slug>-tasks.md` |
| phase·플레이어블 범위 | `docs/design/v0.1-initial-playable.md` |
| 게임 방향·재미 축 | `docs/gdd-cat-tower-casino.md` |

**수정 금지 (피드백으로도 변경하지 않음):** `hand-scoring-v2.md` 족보 규칙, 점수 공식, 리롤 비용·횟수 규칙 — 별도 feature·이슈로 분리.

---

## 4. `/push` (완료)

```mermaid
flowchart TB
  P0["/push"]
  P1["1. 브랜치·diff 범위"]
  P2["2. 문서·코드 정합성\n스펙·Task·AC·diff"]
  P2F{"통과?"}
  P2X["중단\n스펙·코드 수정"]
  P3["3. 커밋 메시지"]
  P4["4. push-feature.sh"]
  P5{"origin/main\n새 커밋?"}
  P6["STOP\nmerge main"]
  P7["main merge + push"]

  P0 --> P1 --> P2 --> P2F
  P2F -->|아니오| P2X
  P2F -->|예| P3 --> P4 --> P5
  P5 -->|있음| P6
  P5 -->|없음| P7
  P6 --> P4
```

```bash
./scripts/start-feature.sh <slug>    # 시작 (또는 /feature Step 2에서 에이전트 실행)
./scripts/push-feature.sh -m "feat: ..."   # 완료
```

---

## 5. 역할 요약

| 주체 | 할 일 |
|------|--------|
| **유저** | `/feature`로 시작 → 스펙·구현 확인 → 피드백(평문) → “완료” → `/push` |
| **에이전트** | 브랜치 생성, 문서→Task→코드, Audit, 피드백마다 스펙 우선 유지 |
| **스크립트** | `start-feature.sh` (브랜치), `push-feature.sh` (커밋+merge) |

## 6. 관련 파일

| 파일 | 용도 |
|------|------|
| `.cursor/skills/feature/SKILL.md` | `/feature` 전체 플로우 |
| `.cursor/rules/feature-scope.mdc` | 브랜치 범위 + 피드백 라운드 (always apply) |
| `.cursor/skills/push/SKILL.md` | `/push` 절차 |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-07 | /push Step 2 문서·코드 정합성 검사 반영 |
| 2026-06-07 | Feature 개발 워크플로 다이어그램 정본 추가 |
