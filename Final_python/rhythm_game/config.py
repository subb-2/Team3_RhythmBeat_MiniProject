# -*- coding: utf-8 -*-
"""
리듬게임 전역 설정 파일 (config.py)

이 파일은 게임 전반에서 사용되는 모든 상수와 설정값을 관리합니다.
UART 통신, 화면 해상도, 색상 팔레트, 곡 목록, 게임 로직 파라미터 등을
한 곳에 모아 유지보수성을 높입니다.

수정 시 주의:
  - 트리거 코드(0x01~0x13)는 FPGA 펌웨어의 송신 코드와 반드시 일치해야 합니다.
  - 색상값은 RGB 또는 RGBA 튜플로 지정합니다.
"""

import os as _os

# ============================================================
# 경로 설정
# ============================================================
# assets 폴더: 앨범 아트 등 정적 리소스가 저장되는 디렉토리 (사용자가 music_data/sing_main_image 로 이전함)
_MUSIC_DATA_DIR = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), "..", "music_data"))
_IMAGE_DIR = _os.path.join(_MUSIC_DATA_DIR, "sing_main_image")

# ============================================================
# UART 시리얼 통신 설정
# ============================================================
# FPGA 보드와 PC 사이의 UART 통신 파라미터.
# FPGA 측 baud rate 설정과 반드시 동일해야 합니다.
UART_PORT = "COM13"             # FPGA가 연결된 COM 포트 번호
UART_BAUDRATE = 115200          # 전송 속도 (bps)
UART_TIMEOUT = 0.01             # 시리얼 읽기 타임아웃 (초), 짧을수록 응답이 빠름

# ============================================================
# 화면 설정
# ============================================================
SCREEN_WIDTH  = 800             # 기본 화면 너비 (전체화면 시 자동 감지로 덮어씌워짐)
SCREEN_HEIGHT = 600             # 기본 화면 높이 (전체화면 시 자동 감지로 덮어씌워짐)
FPS = 60                        # 목표 프레임 레이트
FULLSCREEN = True               # True: 전체화면, False: 창 모드

# ============================================================
# 색상 팔레트 (다크 사이버 네온 테마)
# ============================================================

# -- 배경색 --
COLOR_BG_DARK   = (10, 0, 21)              # 딥 퍼플 (#0a0015)
COLOR_BG_NAVY   = (0, 5, 32)               # 네이비 블루 (#000520)

# -- 네온 강조색 --
COLOR_NEON_CYAN   = (0, 255, 245)           # 시안 (#00fff5) - 주요 강조색
COLOR_NEON_PINK   = (255, 0, 128)           # 핑크 (#ff0080) - 보조 강조색
COLOR_NEON_PURPLE = (180, 0, 255)           # 퍼플 (#b400ff)
COLOR_NEON_BLUE   = (0, 120, 255)           # 블루 (#0078ff)

# -- 글로우 색상 (알파 채널 포함, 반투명 이펙트용) --
COLOR_GLOW_CYAN = (0, 255, 245, 60)
COLOR_GLOW_PINK = (255, 0, 128, 40)

# -- UI 텍스트 색상 --
COLOR_WHITE     = (255, 255, 255)
COLOR_GRAY      = (120, 120, 140)
COLOR_DARK_GRAY = (40, 40, 60)
COLOR_TEXT_DIM   = (80, 80, 100)

# ============================================================
# 곡 목록 (Song List)
# ============================================================
# 각 곡의 메타 정보를 딕셔너리 리스트로 관리합니다.
# - title:      곡 제목 (UI에 표시)
# - artist:     아티스트명
# - difficulty: 난이도 표시 문자열
# - image:      앨범 아트 이미지 경로 (assets 폴더 내)
# - mem_file:   ROM 데이터 파일명 (rom_data 폴더 내, 추후 FPGA 연동 시 사용)
SONG_LIST = [
    {
        "title": "비행기",
        "artist": "가요",
        "difficulty": "★★★★☆",
        "bpm": 120,
        "image": _os.path.join(_IMAGE_DIR, "airplane.png"),
        "mem_file": "airplane.mem",
        "music_file": "airplane.mp3",
    },
    {
        "title": "애상",
        "artist": "가요",
        "difficulty": "★★★☆☆",
        "bpm": 124,
        "image": _os.path.join(_IMAGE_DIR, "aesang.png"),
        "mem_file": "aesang.mem",
        "music_file": "aesang.mp3",
    },
    {
        "title": "die_with_a_smile",
        "artist": "가요",
        "difficulty": "★★★★★",
        "bpm": 79,
        "image": _os.path.join(_IMAGE_DIR, "die_with_a_smile.png"),
        "mem_file": "die_with_a_smile.mem",
        "music_file": "die_with_a_smile.mp3",
    },
]

# 현재 선택된 곡의 인덱스 (화면 간 상태 전달용 전역 변수)
# 곡 선택 화면에서 설정하고, 게임 화면에서 읽어갑니다.
SELECTED_SONG_INDEX = 0


# ============================================================
# state information
# ============================================================
IDLE        = 0b000   # 대기 상태
SELECT      = 0b001   # 곡 선택 상태
READY       = 0b010   # 게임 시작 전 카운트다운(3초)
GAME_CONT   = 0b011   # 게임 플레이 진행
CAPTURE     = 0b100   # 결과 화면 및 사진 캡처
DONE        = 0b101   # 결과 출력 완료 및 대기

# ============================================================
# 게임 플레이 및 렌더링 파라미터 (FPGA 완벽 동기화)
# ============================================================
# FPGA 1프레임당 내려오는 픽셀 수 (FPGA 하드웨어와 맞춤)
LINE_VALUE = 2

# FPGA 기준: 60fps에서 1프레임당 LINE_VALUE 픽셀 이동
FPGA_PIXELS_PER_SEC = 60.0 * LINE_VALUE
HIT_LINE_Y = 420

# ============================================================
# [중요] 싱크 강제 맞춤 설정
# 보드의 물리적 클럭이 달라서 약 2초 만에 떨어지고 있는 물리적 현상이 발생 -> 원래 정확히 60Hz(59.52Hz)로 짜여 있어서 정상이라면 3.5초가 걸려야 함
# ============================================================
USE_CUSTOM_NOTE_SPEED = True
# CUSTOM_NOTE_SPEED = 1.8  # 초시계로 쟀을 때 FPGA에서 떨어지는 데 걸리는 실제 시간(초)
CUSTOM_NOTE_SPEED = 1.85  # 초시계로 쟀을 때 FPGA에서 떨어지는 데 걸리는 실제 시간(초)

if USE_CUSTOM_NOTE_SPEED:
    NOTE_SPEED = CUSTOM_NOTE_SPEED
else:
    # 파이썬은 이 시간만큼 미리(UART TX) 노트를 전송합니다.
    NOTE_SPEED = HIT_LINE_Y / FPGA_PIXELS_PER_SEC

# 파이썬 화면(Pygame->OS->모니터) 출력 지연 시간 보상(초)
UI_RENDER_LATENCY = 0.05
LEAD_IN_TIME = 3.0                    # 게임 시작 시 음악이 나오기 전까지의 대기 시간(초)

# PC UI의 판정선 진행도 (선형 모델로 변경하여 progress=1.0일 때 정확히 판정선 위치)
HIT_LINE_PROGRESS = 1.0 

# ============================================================
# 파티클 설정
# ============================================================
PARTICLE_COUNT     = 150         # 배경에 떠다니는 파티클 개수
PARTICLE_MIN_SIZE  = 1          # 파티클 최소 크기 (px)
PARTICLE_MAX_SIZE  = 2          # 파티클 최대 크기 (px)
PARTICLE_MIN_SPEED = 0.5        # 파티클 최소 이동 속도
PARTICLE_MAX_SPEED = 5.0        # 파티클 최대 이동 속도

# ============================================================
# 전역 상태 변수 (화면 간 데이터 전달용)
# ============================================================
LAST_SCORE = 0                  # 직전 게임에서 획득한 최종 점수
LAST_COMBO = 0                  # 직전 게임에서 획득한 최대 콤보
