# VGA Rhythm Game — "Rhythm Beat"

📅 프로젝트 정보

* 진행 기간: 2026.07.08 ~ 2026.07.20
* 설계 대상: 카메라 손 인식 입력 기반 VGA 리듬 게임 (Main Controller / 판정 및 점수 / VGA 출력 / UART 송수신)
* 기술 스택: `SystemVerilog`, `UVM`, `Vivado`, `Synopsys VCS`, `Basys3`, `OV7670`, `Python(pygame)`

---

## 📝 프로젝트 개요

**카메라로 손 위치를 인식해 조작하는 VGA 리듬 게임**입니다.

<div align="center">
  <img src="https://github.com/user-attachments/assets/3ce1174a-6ce1-47ad-bb32-f75d88cbeb07" width="50%" height="auto">
</div>

### 시스템 설계
1. PC(Python)가 UART로 내려보낸 노트 데이터를 FPGA가 화면에 떨어뜨린 뒤
2. OV7670 카메라 영상에서 붉은 영역을 검출해 4개 레인 중 어느 레인을 눌렀는지 판별
3. 판정(Perfect / Good / Miss), 콤보, 점수를 계산하여 VGA로 출력
4. 게임 결과는 다시 UART로 PC에 전송되어 결과 화면과 리더보드에 반영

### UVM 검증
* 노트 생성 및 판정/점수인 시스템(`top_game`)은 **UVM 검증 환경을 별도로 구축**하여 Directed + Constrained-Random 검증 수행
* 이 과정에서 `score.sv`의 콤보 보너스 RTL 버그를 발견 및 수정하고 Cross Coverage를 40% → 100%로 클로저 진행

---

## 👥 팀 구성

| 이름 | 담당 |
|------|------|
| 김수빈 | 판정 로직(`GameResult`) 및 `top_game` UVM 검증|
| 김지홍 |  |
| 문태성 |  |
| 서어진 |  |
| 송주연 |  |
| 윤수민 |  |
| 조준호 |  |

---

## 🏗️ 시스템 구조

```

<div align="center">
  <img src="https://github.com/user-attachments/assets/4e5a13f9-96e4-4e79-9470-209f25c40627" width="50%" height="auto">
</div>

```

### Main Controller FSM

| 상태 | 인코딩 | 설명 |
|------|--------|------|
| IDLE | `3'b000` | 타이틀 화면 대기 |
| SELECT | `3'b001` | 곡 선택 (btn_l / btn_r self-loop) |
| READY | `3'b010` | 게임 시작 전 3초 카운트다운 |
| GAME_CONT | `3'b011` | 게임 진행 — 판정·점수 누적 구간 |
| CAPTURE | `3'b100` | 결과 화면 및 사진 캡처 (점수 동결) |
| DONE | `3'b101` | 결과 출력 완료 후 IDLE 복귀 |

### 판정 구간 파라미터 (`GameResult.sv`)

| 파라미터 | 값 | 의미 |
|----------|-----|------|
| `ZONE_MIN` | 385 | Good 판정 시작 |
| `PERFECT_MIN` | 405 | Perfect 판정 시작 |
| `PERFECT_MAX` | 445 | Perfect 판정 종료 |
| `ZONE_MAX` | 465 | Good 판정 종료 (초과 시 Miss) |

---

## 🔑 주요 구현 내용

### 1. 노트 관리 (`line_count.sv`)

노트 하나를 **레인(가로) + 낙하 위치(세로)** 한 쌍의 슬롯으로 표현하고, 동시 표시를 위해 슬롯 16개를 두었습니다.

| 신호 | 의미 | 갱신 시점 |
|------|------|-----------|
| `r_posN` | 슬롯 N 노트의 레인 비트마스크 | `i_note` 입력 시 1회 래치 |
| `r_lcntN` | 슬롯 N 노트의 Y좌표 | `v_sync` 하강 에지마다 `+LINE_VALUE(=2)` |
| `cnt` | 다음에 사용할 슬롯 번호 | `i_note` 입력마다 `+1` |

`i_lane`은 슬롯에 값을 복사하고 역할이 끝나는 1프레임 신호이며, 이후 노트 상태는 DUT 내부 레지스터가 보관합니다.

### 2. 판정 및 콤보 (`GameResult.sv`)

슬롯마다 `slot_fsm`을 generate-for로 인스턴스화하여 독립 판정합니다.
카메라 좌표계와 화면 좌표계의 비트 순서가 반대이므로 `judge_region`에서 좌우 반전 후 비교합니다.

| 출력 | 형태 | 조건 |
|------|------|------|
| `perfect` | pulse | 입력 레인 일치 && `405 ≤ lcnt ≤ 445` |
| `good` | pulse | 입력 레인 일치 && zone 내부 (perfect 구간 제외) |
| `miss` | pulse | `lcnt > 465` 통과 또는 오타 입력 |
| `combo_done` | pulse | Miss 다음 클럭에 1회 (`combo_data` 안정화 후) |
| `fever` | level | `perfect && combo_cnt == 3` 에서 ON, `miss`에서 OFF |

### 3. 점수 규칙 (`score.sv`)

```systemverilog
assign score = basic_score + combo_score;
```

**기본 점수 — 판정마다**

| 판정 | 평상시 | Fever |
|------|--------|-------|
| Perfect | +100 | +200 |
| Good | +50 | +100 |
| Miss | 0 | 0 |

**콤보 보너스 — 콤보가 끊길 때 한 번** (`combo_reg = n(n+1)`, n = 끊기기 직전 콤보)

| 구간 | 조건 | 가산값 |
|------|------|--------|
| 1단 | `combo_reg ≤ 101` | `combo_reg >> 1` |
| 2단 | `combo_reg ≤ 2550` | `combo_reg` |
| 3단 | 그 외 | `(combo_reg * 3) >> 1` |

점수는 `main_state == GAME_CONT`인 동안에만 누적되고, `CAPTURE` 진입 시 동결됩니다.

### 4. PC 연동 (Python / pygame)

* `convert_notes.py` — 계이름·박자로 작성한 악보 텍스트를 레인 Hex + 시간 정보의 `.mem` 롬 데이터로 변환
* `uart_handler.py` — 115200bps 시리얼로 FPGA 상태 코드 수신 및 노트 데이터 송신
* `screens/` — 타이틀 / 곡 선택 / 게임 / 결과 화면, `leaderboard.json` 기반 랭킹 저장

### 5. UVM 검증 환경 (`Final_UVM/`)

검증 대상은 `top_game`(= `line_count` + `GameResult` + `score`)이며, VCS 환경에서 구동했습니다.

| 테스트 | 시나리오 |
|--------|----------|
| `rhythmGame_perfect_test` | 판정선 중앙 타이밍 입력 |
| `rhythmGame_good_test` | 판정선 도달 직전 입력 |
| `rhythmGame_miss_test` | 입력 없이 `ZONE_MAX` 통과 |
| `rhythmGame_ignore_early_press_test` | 조기 입력 무시 후 정상 타이밍 재입력 |
| `rhythmGame_random_test` | 레인 / 타이밍 / 오타 여부 Constrained-Random 40회 |
| `rhythmGame_combobonus_test` | Perfect 연속 → Miss 반복으로 콤보 보너스 관측 |
| `rhythmGame_closure_test` | 노트 레인 4 × 입력 레인 4 × 타이밍 3 + 미입력 4 = 52회 전수 실행 |

**Coverage 클로저 결과**

| 로그 | Overall | Cross(lane, press) | Cross(lane, verdict) | Error |
|------|---------|--------------------|----------------------|-------|
| `random_single_40_sim.log` | 88.0% | 40.0% | 100.0% | 0 |
| `random_70_sim.log` | 94.0% | 70.0% | 100.0% | 0 |
| **`closure_sim.log`** | **100.0%** | **100.0%** | **100.0%** | **0** |

---

## 🚀 문제 해결 (Troubleshooting)

### 1. `score.sv` 콤보 보너스 누락 — RTL 버그

* **문제**: Perfect 10연속 후 Miss, Perfect 3연속 후 Miss 시나리오에서 스코어보드 기댓값 116점과 DUT 실제값 110점이 불일치.
* **원인**: `combo_reg <= combo_data * (combo_data + 1);` 로 논블로킹 대입한 값을 같은 always 블록에서 `if (combo_reg)`로 즉시 읽어, **직전 콤보의 값**으로 보너스를 계산. 첫 보너스는 `combo_reg`가 X여서 통째로 유실.
* **해결**: `combo_reg`를 조합 논리 `assign combo_reg = combo_data * (combo_data + 1);` 로 전환.
* **결과**: `ComboBonus_seq` 재실행 시 보너스 110 / 116이 각각 정상 반영, Error 0.

### 2. Lane Coverage 0% 고착

* **문제**: 자극을 늘려도 `cp_lane` 커버리지가 0%에서 움직이지 않음.
* **원인**: 모니터가 `lane_data`를 매 클럭 샘플링하는데, 노트 생성 프레임 외에는 `lane_data`가 `4'b0000`이라 유효 bin에 들어가지 않음.
* **해결**: `note_start`가 1인 시점의 `lane_data`만 `active_lane`에 래치하도록 샘플 조건 수정. 자극은 그대로 두고 관측만 고쳤습니다.

### 3. 스코어보드 상시 Mismatch

* **문제**: 판정 펄스 시점에 `score`/`combo`를 비교하면 매 트랜잭션이 불일치.
* **원인**: 기본 점수는 판정 다음 클럭(T+1), 콤보 보너스는 `combo_done`을 거쳐 T+2에 반영되는 파이프라인 차이.
* **해결**: 모니터에서 `score`/`combo`를 한 클럭 늦게 샘플링하고(`fever`는 판정 시점 유지), 스코어보드에 `pending_bonus`를 두어 보너스를 다음 트랜잭션에 가산.

### 4. Cross Coverage 40% 한계

* **문제**: 랜덤 반복 횟수를 늘려도 `cross(lane, press)`가 40%를 넘지 못함.
* **원인**: 시퀀스가 `press_region(lane_to_region(lane))` 형태로 **노트 레인과 입력 레인에 같은 변수**를 사용해, 오타 조합(노트 1레인 / 입력 2레인 등)이 구조적으로 생성 불가능.
* **해결**: `rand bit [3:0] press_lane`을 분리하고 65% 정타 / 35% 오타 dist 제약 추가 → 70% 도달. 이후 `closure_test`에서 `foreach` + inline constraint로 20개 bin을 전수 실행하여 100% 달성 (`c_wrong.constraint_mode(0)`으로 제약 충돌 회피).

---

## 📚 배운 점

* **커버리지 0%는 자극이 아니라 관측의 문제일 수 있다**: Lane Cover 0%의 원인이 시퀀스가 아니라 모니터 샘플 조건이었습니다. 커버리지가 오르지 않을 때 자극을 늘리기 전에 샘플 시점부터 확인해야 한다는 것을 체감했습니다.
* **Cross Coverage는 시퀀스 구조가 상한을 정한다**: 입력 레인이 노트 레인 변수에 묶여 있으면 반복 횟수와 무관하게 도달 불가능한 bin이 생깁니다. 랜덤화 대상을 분리해야 비로소 조합 공간이 열린다는 것을 수치로 확인했습니다.
* **논블로킹 대입의 읽기 시점**: `<=`로 갱신한 변수를 같은 블록에서 읽으면 이전 값이 읽힌다는 기본 규칙이, 실제 게임 점수 6점 차이로 드러났습니다. Directed 테스트로 재현 조건을 좁혀 원인을 증명한 뒤 수정하는 흐름을 경험했습니다.
* **DUT의 파이프라인은 스코어보드 모델에 반영되어야 한다**: 점수와 보너스의 반영 클럭이 다르다는 사실을 모델에 넣지 않으면, RTL이 맞아도 전부 FAIL로 보입니다.

---

## 📌 향후 개선 방향

* `v_sync` 글리치 필터가 주석 처리된 상태 — UART 고속 통신 시 동기 신호 노이즈 대응 필요
* 노트 슬롯 16개 고정 — 고밀도 채보에서 슬롯 부족 가능성
* Assertion(SVA) 미적용 — 판정 구간 및 콤보 리셋 조건에 대한 프로퍼티 추가 여지
* 점수 반영 지연(T+1 / T+2) 정규화 시 스코어보드의 `pending_bonus` 로직 단순화 가능
* PC 통신은 폴링 기반 — 인터럽트 방식 미지원

---

## 🖥️ 개발 환경

| 항목 | 내용 |
|------|------|
| HDL | SystemVerilog / Verilog |
| 검증 | UVM, Synopsys VCS W-2024.09-SP1 |
| EDA Tool | Xilinx Vivado |
| 타겟 보드 | Digilent Basys3 (Xilinx Artix-7) |
| 카메라 | OV7670 (SCCB 설정) |
| PC 측 | Python 3, pygame, pyserial |

---

## 📁 파일 구성

```text
├── Final_verilog/최종_verilog/          # Vivado 프로젝트 (0715_mini_Project_final)
│   └── ...srcs/sources_1/imports/
│       ├── maincontroller/
│       │   ├── MainControl.sv           # 게임 진행 FSM (IDLE~DONE)
│       │   ├── GameResult.sv            # 판정 / 콤보 / fever 생성
│       │   ├── score.sv                 # 기본 점수 + 콤보 보너스 누적
│       │   └── BtnDebouncer.sv          # 물리 버튼 디바운싱
│       ├── VGA/
│       │   ├── OV7670_SCCB_Controller.sv # 카메라 레지스터 설정
│       │   ├── SCCB_sender.sv / i2c_master.sv
│       │   ├── OV7670MemController.sv    # 픽셀 → 프레임버퍼 write
│       │   ├── frameBuffer.sv / framePrinter.sv / VGA_Decoder.sv
│       │   └── Region_Detector.sv        # 붉은 영역 검출 → region[3:0]
│       ├── uart receiver/
│       │   ├── MainController.sv         # 게임 FSM + top_game 통합
│       │   ├── top_module.sv (top_game)  # line_count + GameResult + score
│       │   ├── linecounter.sv            # 노트 슬롯 16개 낙하 관리
│       │   ├── uart_rx.sv / receiver.sv / fifo.sv
│       │   └── top.sv                    # 최상위 모듈
│       └── constrs_1/Basys-3-Master.xdc  # 핀 제약
│
├── Final_UVM/                            # UVM 검증 환경
│   ├── rtl/                              # 검증 대상 RTL 사본
│   │   ├── top_game.sv / line_count.sv / GameResult.sv / score.sv
│   ├── tb/
│   │   ├── tb_rhythmGame.sv              # top 테스트벤치
│   │   ├── rhythmGame_interface.sv       # 인터페이스 / 클로킹 블록
│   │   ├── rhythmGame_seq_item.sv        # 트랜잭션 정의
│   │   ├── rhythmGame_sequence.sv        # Perfect/Good/Miss/Random/ComboBonus 시퀀스
│   │   ├── rhythmGame_driver.sv / monitor.sv / agent.sv / env.sv
│   │   ├── rhythmGame_scoreboard.sv      # 예상 점수·콤보 독립 계산 및 비교
│   │   ├── rhythmGame_coverage.sv        # covergroup (lane / region / verdict / cross)
│   │   └── rhythmGame_test.sv            # 테스트 클래스 모음
│   ├── random_single_40_sim.log          # Cross 40% (개선 전)
│   ├── random_70_sim.log                 # Cross 70% (press_lane 분리 후)
│   └── closure_sim.log                   # Cross 100% (클로저 테스트)
│
├── Final_python/                         # PC 측 리듬게임
│   ├── rhythm_game/
│   │   ├── main.py                       # 진입점 / 메인 루프
│   │   ├── config.py                     # UART·화면·판정 상수
│   │   ├── uart_handler.py               # 시리얼 송수신
│   │   ├── leaderboard.py                # 랭킹 저장
│   │   └── screens/                      # start / select / game / result
│   └── music_data/
│       ├── rom_data/convert_notes.py     # 악보 텍스트 → .mem 변환
│       ├── rom_data/*.mem                # 곡별 노트 롬 데이터
│       └── sing_main_image/, *.mp3       # 앨범 아트 및 음원
│
├── Team3_RhythmBeat_Mini_Project.pptx    # 발표 자료
└── Team3_RhythmBeat_Mini_Project.pdf
```
