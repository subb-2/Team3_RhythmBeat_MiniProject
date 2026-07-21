# -*- coding: utf-8 -*-
"""
게임 화면 (Game Screen) 모듈

실제로 플레이어가 리듬 액션 게임을 조작하고 노트를 타격하는 메인 화면입니다.
가짜 3D 투시(Perspective)를 이용해 상단 중앙에서 하단 가장자리로
넓게 퍼지는 레인을 렌더링하여 고전 아케이드 리듬 게임의 원근감을 시뮬레이션합니다.

주요 구성 요소:
- GameScreen: 화면의 라이프사이클 관리, 물리적인 렌더링, 이벤트 감지 처리.
- Note: 각 레인 위에서 판정선을 향해 스크롤 되는 노트 객체 모델.
- HitParticle / HitFlash: 노트를 정확히 눌렀을 때 터져나오는 화려한 네온 파티클과 광원 효과.

FPGA 통신 연동:
  - UART 채널로부터 전달되는 트리거 코드에 따라 (0x10 ~ 0x13)
  - FPGA 하드웨어 버튼이 소프트웨어의 키보드(A,S,D,F)와 똑같은 타격 동작을 수행하도록
    `handle_trigger()` 내부에서 `TRIGGER_KEY_MAP`을 조회해 판정을 실행합니다.
"""

import pygame
import math
import random
import os

from screens.base_screen import BaseScreen
import config
# 게임 내 세부 난이도 파라미터 및 색상을 전역 설정에서 통일시켜 불러옴
from config import (
    COLOR_BG_DARK, COLOR_BG_NAVY,
    COLOR_NEON_CYAN, COLOR_NEON_PINK, COLOR_NEON_PURPLE, COLOR_NEON_BLUE,
    COLOR_WHITE, COLOR_GRAY, COLOR_TEXT_DIM,
    NOTE_SPEED, HIT_LINE_PROGRESS, UI_RENDER_LATENCY,
    PARTICLE_COUNT, PARTICLE_MIN_SIZE, PARTICLE_MAX_SIZE,
    PARTICLE_MIN_SPEED, PARTICLE_MAX_SPEED,
)
import leaderboard

# ============================================================
# 색상 상수
# ============================================================
# 인게임 플레이의 배경, 그라데이션, 그리고 트랙 등을 렌더링하기 위한 레트로 다크 톤 조합
C_BG_GAME = (5, 2, 18)            # 깊고 어두운 남색 계열 최상단 배경
C_BG_GRADIENT = (12, 4, 30)       # 화면 하단으로 내려올수록 짙어지는 바닥 그라데이션
C_LANE_BG = (18, 8, 45)           # 트랙 안쪽의 기본 불투명 바닥 색상
C_LANE_LINE = (70, 35, 140)       # 레인을 4칸으로 나누는 세로줄의 기본 컬러 (밝은 퍼플)
C_LANE_GLOW = (0, 200, 255)       # 레인 클릭 시 순간적으로 번지는 글로우 효과
C_HIT_LINE = (255, 100, 200)      # 타격 타이밍을 알려주는 하단 가로 선 (네온 핑크)
C_GRID_LINE = (30, 15, 70)        # 시각적인 속도감을 더해주는 수평 이동선용 어두운 보라
C_TRACK_EDGE = (120, 40, 220)     # 게임 영역 트랙의 외곽 양 모서리 빛기둥 색상

# 각 4개의 레인(A,S,D,F 키 매핑) 고유의 식별 색상 및 번짐(글로우) 코어 
C_NOTE_COLORS = [
    (0, 220, 255),    # 레인 0 (A) - 밝고 시원한 시안
    (255, 50, 180),   # 레인 1 (S) - 핫 핑크
    (180, 80, 255),   # 레인 2 (D) - 강렬한 퍼플
    (50, 255, 150),   # 레인 3 (F) - 네온 민트 그린
]

C_NOTE_GLOW = [
    (0, 180, 220),
    (220, 30, 150),
    (150, 60, 220),
    (30, 220, 120),
]


# ============================================================
# 시각 이펙트 클래스
# ============================================================
class HitParticle:
    """
    타격 파티클 이펙트
    
    사용자가 정확한 타이밍에 노트를 눌렀을 때 타격 지점(판정선)을 중심으로
    터져나가는 작은 파편 가루 조각입니다. 중력의 영향을 받아 포물선을 그리며 사라집니다.
    """
    def __init__(self, x, y, color):
        """파티클의 초기 위치와 랜덤한 분출 각도/속력을 세팅합니다."""
        self.x = x
        self.y = y
        self.color = color
        self.vx = random.uniform(-150, 150)
        self.vy = random.uniform(-200, -50)
        self.life = 1.0
        self.size = random.uniform(2, 5)

    def update(self, dt):
        """중력값을 적용하여 y속도를 증가시키며 위치를 업데이트합니다."""
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.vy += 300 * dt  # 아래 방향으로 떨어지는 중력
        self.life -= dt * 2.5
        return self.life > 0

    def draw(self, surface):
        """생명 주기(life)에 따라 크기와 알파값을 점점 줄이며 그립니다."""
        alpha = int(255 * max(0, self.life))
        if alpha > 5:
            s = max(1, int(self.size * self.life * 2))
            color = self.color[:3]
            pygame.draw.circle(surface, color, (int(self.x), int(self.y)), s)


class HitFlash:
    """
    타격 빔 플래시 이펙트
    
    파티클과 동시에 판정선 가로축을 중심으로 넓고 선명한 십자/가로선 형태의
    빛줄기가 매우 짧은 시간 반짝이는 이펙트를 만듭니다. (Perfect 판정 시 더욱 강렬함)
    """
    def __init__(self, x, y, width, color, is_perfect=False):
        self.x = x
        self.y = y
        self.width = width
        self.color = color
        self.is_perfect = is_perfect
        self.life = 1.0
        # Perfect 여부에 따라 플래시가 남아있는 최대 유지 프레임 시간을 달리 둠
        self.max_life = 0.4 if is_perfect else 0.25

    def update(self, dt):
        self.life -= dt / self.max_life
        return self.life > 0

    def draw(self, surface):
        if self.life <= 0:
            return
        
        alpha = max(0, int(200 * self.life))
        spread = int((1.0 - self.life) * (80 if self.is_perfect else 40))

        # 좌우로 길게 뻗어나가는 빔의 범위를 포괄하는 투명 도화지 생성
        flash_surf = pygame.Surface((self.width + spread * 2, spread * 2 + 6), pygame.SRCALPHA)
        cx = flash_surf.get_width() // 2
        cy = flash_surf.get_height() // 2

        # 3단계의 두께와 투명도를 가진 흐린 네모(선)들을 겹쳐 그려 글로우 효과
        for i in range(3):
            layer_alpha = max(0, alpha - i * 50)
            h = max(1, spread - i * 8)
            w = self.width + spread * 2 - i * 20
            if w > 0 and h > 0 and layer_alpha > 0:
                rect = pygame.Rect(cx - w // 2, cy - h // 2, w, h)
                pygame.draw.rect(flash_surf, (*self.color[:3], layer_alpha), rect, border_radius=max(1, h // 2))

        # 가장 중심이 되는 흰색에 가까운 얇고 밝은 핵(Core) 선 그리기
        bright = (min(255, self.color[0] + 100), min(255, self.color[1] + 100), min(255, self.color[2] + 100))
        core_alpha = max(0, int(255 * self.life))
        pygame.draw.line(flash_surf, (*bright, core_alpha),
                        (cx - self.width // 2, cy), (cx + self.width // 2, cy), 2)

        surface.blit(flash_surf, (int(self.x - flash_surf.get_width() // 2),
                                   int(self.y - flash_surf.get_height() // 2)))


# ============================================================
# 노트 모델 클래스
# ============================================================
class Note:
    """
    떨어지는 개별 리듬 노트 객체

    생성 시각과 도달 시각을 기반으로 게임 내 프레임 시간에 의존해
    자신의 현재 y좌표(진행률 0.0 ~ 1.0)를 스스로 반환합니다.
    """
    def __init__(self, lane, spawn_time, hit_time):
        self.lane = lane
        self.spawn_time = spawn_time
        self.hit_time = hit_time
        
        # 맞췄는지 놓쳤는지의 판정 플래그
        self.is_hit = False
        self.is_missed = False

    def get_progress(self, current_time):
        """
        현시점의 곡(혹은 게임) 플레이 시간을 넣으면 노트가 화면 상단부터
        판정선까지 내려온 진행 백분율(비율)을 0.0 ~ 1.0 사이 값으로 계산해 넘겨줍니다.
        """
        total_time = self.hit_time - self.spawn_time
        elapsed = current_time - self.spawn_time
        # 판정선(HIT_LINE_PROGRESS)에 도달하는 순간이 정확히 elapsed == total_time이 되도록 스케일링합니다.
        return (elapsed / total_time) * config.HIT_LINE_PROGRESS


# ============================================================
# 메인 게임 스크린 클래스
# ============================================================
class GameScreen(BaseScreen):
    """게임 플레이 화면 및 전체적인 노트와 판정 렌더링/로직 시스템 제어기"""

    # --------------------------------------------------------
    # 초기화 
    # --------------------------------------------------------
    def __init__(self, screen, clock):
        super().__init__(screen, clock)
        self.sw = screen.get_width()
        self.sh = screen.get_height()

        self.time = 0.0
        
        # 실시간 오프셋 조정 기능 제거됨
        song_info = config.SONG_LIST[config.SELECTED_SONG_INDEX]

        # 키 맵핑 정보 세팅 (A, S, D, F 키보드 물리 키 대응 배열)
        self.keys = [pygame.K_a, pygame.K_s, pygame.K_d, pygame.K_f]
        self.key_states = [False, False, False, False]
        self.key_glows = [0.0, 0.0, 0.0, 0.0]  # 키를 눌렀을 때 레인 하이라이트 투명도 

        self.notes = []
        self.combo = 0
        self.max_combo = 0
        self.score = 0
        # 화면 중앙 부근에 잠깐 뜨고 사라질 판정 텍스트들({"text": "PERFECT", "time": ..., "color": ...})
        self.judgments = []  

        self.hit_particles = []
        self.hit_flashes = []

        # --- UI 애니메이션용 변수들 ---
        self.score_display = 0          # 실제 점수판이 부드럽게 올라가도록 지연 계산하는 표시용 점수
        self.score_pulse = 0.0          # 점수가 오를 때 테두리가 반짝거리는 펄스 효과 플래그
        self.combo_bounce = 0.0         # 콤보 수가 상승할 때 글씨가 쿵 뛰는 바운스 효과치
        self.prev_combo = 0             

        # 우주 공간을 날아가는 듯한 별 점들
        self.bg_stars = []
        for _ in range(30):
            self.bg_stars.append({
                "x": random.randint(0, self.sw),
                "y": random.randint(0, self.sh),
                "size": random.randint(1, 2),
                "alpha": random.randint(80, 200),
                "pulse_speed": random.uniform(1.0, 3.0),
                "pulse_offset": random.uniform(0, math.pi * 2),
            })

        # 다가오는 트랙망 바닥 선 
        self.grid_scroll = 0.0

        # 임시 노트 생성기용 전역 파라미터 로드
        self.next_note_time = self.time + 2.0
        self.note_speed = NOTE_SPEED  
        self.hit_line_progress = HIT_LINE_PROGRESS  

        # 정적 파일들(폰트 등) 준비
        self._init_fonts()
        self._init_cached_surfaces()
        self.reset()

    def reset(self):
        """
        곡을 선택하고 화면이 시작될 때마다 과거 데이터 리셋 및 초기화.
        """
        pygame.mixer.music.stop()
        
        song_info = config.SONG_LIST[config.SELECTED_SONG_INDEX]
        
        self.time = 0.0
        self.play_time = 0.0 # 기본값, _load_song 이후 재계산
        self.state = "PLAYING"
        self.countdown_time = 0.0
        self.key_states = [False, False, False, False]
        self.key_glows = [0.0, 0.0, 0.0, 0.0]
        self.last_lane = 0
        self.notes = []
        self.raw_notes = []
        self.pending_tx_notes = []
        self.combo = 0
        self.max_combo = 0
        self.score = 0
        self.fever = False
        self.fever_glow = 0.0
        self.music_loaded = False
        self.judgments = []
        self.hit_particles = []
        self.hit_flashes = []
        self.score_display = 0
        self.score_pulse = 0.0
        self.combo_bounce = 0.0
        self.prev_combo = 0
        self.next_note_time = self.time + 2.0
        
        self.last_note_hit_time = None
        self.done_signal_sent = False
        
        self._load_song()
        
        # 첫 번째 노트가 떨어지기 시작하는 시간(spawn_time)을 확인하여,
        # 음수라면 그만큼만 리드인(대기 시간)을 부여하고, 아니면 즉시(0초) 시작합니다.
        req_lead_in = 0.0
        if self.pending_tx_notes:
            first_spawn = self.pending_tx_notes[0]["spawn_time"]
            if first_spawn < 0.0:
                req_lead_in = abs(first_spawn)
        
        self.play_time = -req_lead_in
        
        # 시작 대기(리드인)가 끝나면 음악을 재생하기 위한 플래그
        self.music_needs_start = True

    def _load_song(self):
        """ROM 데이터를 읽어와 self.raw_notes에 로드합니다. (상대적 gap 포맷)"""
        song_info = config.SONG_LIST[config.SELECTED_SONG_INDEX]
        print(f"[DEBUG] _load_song() called. SELECTED_SONG_INDEX={config.SELECTED_SONG_INDEX}, song_info={song_info['title']}")
        mem_filename = song_info.get("mem_file")
        if not mem_filename:
            return
            
        rom_path = os.path.join(config._MUSIC_DATA_DIR, "rom_data", mem_filename)
        
        try:
            with open(rom_path, "r") as f:
                for line in f:
                    line = line.strip()
                    parts = line.split()
                    if len(parts) < 2:
                        continue
                    
                    lane_hex = parts[0]
                    gap_beats = float(parts[1])
                    lane_val = int(lane_hex, 16)
                    
                    lanes = []
                    if lane_val & 0x08: lanes.append(0)
                    if lane_val & 0x04: lanes.append(1)
                    if lane_val & 0x02: lanes.append(2)
                    if lane_val & 0x01: lanes.append(3)
                    # if not lanes: continue 제거됨 (레인 0 허용)
                    
                    self.raw_notes.append({
                        "gap_beats": gap_beats,
                        "lane_val": lane_val,
                        "lanes": lanes
                    })
                    
            print(f"[ROM 로드] {mem_filename} 파일에서 총 {len(self.raw_notes)}개의 노트를 로드했습니다.")
            
            # 초기 시간 계산 (recalculate_notes 활용)
            self._recalculate_notes()
            
        except Exception as e:
            print(f"Failed to load rom data: {e}")
            
        # 음악 로드
        music_filename = song_info.get("music_file")
        if music_filename:
            music_path = os.path.join(config._MUSIC_DATA_DIR, music_filename)
            print(f"[DEBUG] Loading music: {music_path}")
            if os.path.exists(music_path):
                try:
                    pygame.mixer.music.load(music_path)
                    self.music_loaded = True
                    print(f"[DEBUG] Music loaded successfully: {music_filename}")
                except Exception as e:
                    print(f"Failed to load music: {e}")
            else:
                print(f"Music file not found at: {music_path}")

    def _recalculate_notes(self):
        """
        상대적 gap 기반으로 모든 노트의 hit_time을 체이닝 계산합니다.
        """
        if not self.raw_notes:
            return
            
        song_info = config.SONG_LIST[config.SELECTED_SONG_INDEX]
        bpm = song_info.get("bpm", 120)
        base_sec_per_beat = 60.0 / bpm
        
        # 첫 노트: 곡 시작으로부터의 절대 오프셋
        accumulated_time = self.raw_notes[0]["gap_beats"] * base_sec_per_beat
        self.raw_notes[0]["hit_time"] = accumulated_time
        self.raw_notes[0]["spawn_time"] = accumulated_time - config.NOTE_SPEED
        
        # 나머지 노트: 이전 노트로부터 상대적 gap * sec_per_beat
        for i in range(1, len(self.raw_notes)):
            gap_seconds = self.raw_notes[i]["gap_beats"] * base_sec_per_beat
            accumulated_time += gap_seconds
            self.raw_notes[i]["hit_time"] = accumulated_time
            self.raw_notes[i]["spawn_time"] = accumulated_time - config.NOTE_SPEED
        
        # ----------------------------------------------------
        # 1. 음악 재생 전일 경우, 첫 노트 스폰 시간에 1초의 여유(리드인)를 줍니다.
        # 이렇게 해야 화면 진입 후 1초 대기 -> 상단에서 노트 정상 출발 -> 음악 재생이 부드럽게 이어집니다.
        # ----------------------------------------------------
        if not pygame.mixer.music.get_busy():
            req_lead_in = 1.0
            if self.raw_notes:
                first_spawn = self.raw_notes[0]["spawn_time"]
                if first_spawn < 0.0:
                    req_lead_in = abs(first_spawn) + 1.0
                elif first_spawn < 1.0:
                    req_lead_in = 1.0 - first_spawn
            self.play_time = -req_lead_in

        # 현재 갱신된 play_time 기준으로 pending_tx_notes와 active_notes 재구성
        self.pending_tx_notes = []
        self.notes = []
        
        for r in self.raw_notes:
            if r["spawn_time"] >= self.play_time:
                self.pending_tx_notes.append(r.copy())
            elif r["hit_time"] + 0.5 > self.play_time:
                for lane in r["lanes"]:
                    self.notes.append(Note(lane, r["spawn_time"], r["hit_time"]))
                    
        self.pending_tx_notes.sort(key=lambda x: x["spawn_time"])
        
        if self.raw_notes:
            self.last_note_hit_time = max(r["hit_time"] for r in self.raw_notes)
        else:
            self.last_note_hit_time = None


    # --------------------------------------------------------
    # 렌더링 리소스 준비 / 캐싱
    # --------------------------------------------------------
    def _init_cached_surfaces(self):
        """
        정적인 뒷배경이나 복잡하지만 움직이지 않는 선들을
        단 한번만 렌더링하여 Surface 형태로 캐싱하여 프레임 드랍을 막습니다.
        """
        # 1. 배경 화면 캐싱
        self._bg_surface = pygame.Surface((self.sw, self.sh))
        for y in range(0, self.sh, 2):
            ratio = y / self.sh
            r = int(C_BG_GAME[0] * (1 - ratio) + C_BG_GRADIENT[0] * ratio)
            g = int(C_BG_GAME[1] * (1 - ratio) + C_BG_GRADIENT[1] * ratio)
            b = int(C_BG_GAME[2] * (1 - ratio) + C_BG_GRADIENT[2] * ratio)
            pygame.draw.rect(self._bg_surface, (r, g, b), (0, y, self.sw, 2))

        # 2. CRT 브라운관 텍스쳐 필터 마스크
        self._scanline_surface = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        for y in range(0, self.sh, 3):
            pygame.draw.line(self._scanline_surface, (0, 0, 0, 20), (0, y), (self.sw, y), 1)

        # 3. 빈 알파 캔버스 (매번 투명 효과를 덮어 그릴 때 쓰임)
        self._track_overlay = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)

        # 4. 트랙 좌우 테두리의 두꺼운 네온 글로우 선
        self._track_border = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        _, top_w = self._get_projection(0)
        _, bot_w = self._get_projection(1.0)
        top_lx = (self.sw - top_w) / 2
        top_rx = top_lx + top_w
        bot_lx = (self.sw - bot_w) / 2
        bot_rx = bot_lx + bot_w
        
        # 바깥쪽 흐린 외곽 글로우 처리 (그라데이션 빛번짐)
        for gi in range(12):
            alpha = max(0, 45 - gi * 4)
            pygame.draw.line(self._track_border, (*C_TRACK_EDGE[:3], alpha),
                           (int(top_lx) - gi, 0), (int(bot_lx) - gi, self.sh), 1)
            pygame.draw.line(self._track_border, (*C_TRACK_EDGE[:3], alpha),
                           (int(top_rx) + gi, 0), (int(bot_rx) + gi, self.sh), 1)
                           
        # 안쪽 코어 라인
        for gi in range(3):
            alpha = max(0, 180 - gi * 50)
            pygame.draw.line(self._track_border, (*C_TRACK_EDGE[:3], alpha),
                           (int(top_lx) - gi, 0), (int(bot_lx) - gi, self.sh), 2)
            pygame.draw.line(self._track_border, (*C_TRACK_EDGE[:3], alpha),
                           (int(top_rx) + gi, 0), (int(bot_rx) + gi, self.sh), 2)

        # 5. 4개의 레인을 세로로 분할하는 3개의 라인 + 맨 우측 라인
        self._lane_lines = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        segments = 28
        max_p = 440.0 / 420.0  # 하단 판정선(440)까지 연장
        for i in range(segments):
            p1 = (i / segments) * max_p
            p2 = ((i + 1) / segments) * max_p
            y1, w1 = self._get_projection(p1)
            y2, w2 = self._get_projection(p2)
            line_alpha = min(255, int(240 + 160 * (p1 ** 0.5)))
            for lane in range(4):
                x1, lw1 = self._get_lane_x(lane, w1)
                x2, lw2 = self._get_lane_x(lane, w2)
                pygame.draw.line(self._lane_lines, (*C_LANE_LINE[:3], line_alpha),
                               (int(x1), int(y1)), (int(x2), int(y2)), 3)
                if lane == 3:
                    pygame.draw.line(self._lane_lines, (*C_LANE_LINE[:3], line_alpha),
                                   (int(x1 + lw1), int(y1)), (int(x2 + lw2), int(y2)), 3)

        # 6. 하단 고정 타격 가이드(판정선) 이미지 캐싱 (380~440 범위)
        self._hitline_surface = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        
        # 상단(380), 중앙(410), 하단(440) 투시 좌표 계산
        p_top = 380.0 / 420.0
        p_mid = 410.0 / 420.0
        p_bot = 440.0 / 420.0
        y_top, w_top = self._get_projection(p_top)
        y_mid, w_mid = self._get_projection(p_mid)
        y_bot, w_bot = self._get_projection(p_bot)
        
        x_top_l, _ = self._get_lane_x(0, w_top)
        x_top_r = x_top_l + w_top
        x_mid_l, _ = self._get_lane_x(0, w_mid)
        x_mid_r = x_mid_l + w_mid
        x_bot_l, _ = self._get_lane_x(0, w_bot)
        x_bot_r = x_bot_l + w_bot
        
        # 380 상단 경계선 (굵은 네온 핑크)
        pygame.draw.line(self._hitline_surface, (*C_HIT_LINE[:3], 200),
                        (int(x_top_l), int(y_top)), (int(x_top_r), int(y_top)), 3)
        # 440 하단 경계선 (굵은 네온 핑크)
        pygame.draw.line(self._hitline_surface, (*C_HIT_LINE[:3], 200),
                        (int(x_bot_l), int(y_bot)), (int(x_bot_r), int(y_bot)), 3)
        # 410 가상 판정 기준 라인 (밝은 흰핑크, 얇게)
        pygame.draw.line(self._hitline_surface, (255, 220, 245, 150),
                        (int(x_mid_l), int(y_mid)), (int(x_mid_r), int(y_mid)), 1)
        
        self._hitline_y = y_mid

        # 7. 레인의 바닥 질감 타일. 짝수 레인과 홀수 레인의 색을 조금 달리하여 구분이 명확하도록.
        self._track_base = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        for i in range(segments):
            p1 = (i / segments) * max_p
            p2 = ((i + 1) / segments) * max_p
            y1, w1 = self._get_projection(p1)
            y2, w2 = self._get_projection(p2)
            
            for lane in range(4):
                x1, lw1 = self._get_lane_x(lane, w1)
                x2, lw2 = self._get_lane_x(lane, w2)
                pts = [(x1, y1), (x1 + lw1, y1), (x2 + lw2, y2), (x2, y2)]
                
                if lane % 2 == 0:
                    lane_color = (22, 10, 50, 240)
                else:
                    lane_color = (30, 15, 60, 240)
                    
                pygame.draw.polygon(self._track_base, lane_color, pts)

    def _init_fonts(self):
        """점수 표시 및 판정 이펙트를 그릴 폰트 준비 과정"""
        korean_fonts = ["malgun gothic", "malgungothic", "gulim", "dotum"]
        font_name = None
        for fname in korean_fonts:
            if fname in [f.lower() for f in pygame.font.get_fonts()]:
                font_name = fname
                break

        scale = self.sh / 600.0
        if font_name:
            self.font_combo = pygame.font.SysFont(font_name, int(58 * scale), bold=True)
            self.font_combo_label = pygame.font.SysFont(font_name, int(16 * scale), bold=True)
            self.font_score = pygame.font.SysFont(font_name, int(32 * scale), bold=True)
            self.font_score_label = pygame.font.SysFont(font_name, int(12 * scale), bold=True)
            self.font_judge = pygame.font.SysFont(font_name, int(52 * scale), bold=True)
            self.font_key = pygame.font.SysFont(font_name, int(26 * scale), bold=True)
        else:
            self.font_combo = pygame.font.Font(None, int(72 * scale))
            self.font_combo_label = pygame.font.Font(None, int(20 * scale))
            self.font_score = pygame.font.Font(None, int(40 * scale))
            self.font_score_label = pygame.font.Font(None, int(16 * scale))
            self.font_judge = pygame.font.Font(None, int(66 * scale))
            self.font_key = pygame.font.Font(None, int(32 * scale))

    def _get_projection(self, p):
        """
        화면 최상단 0.0에서 최하단 1.0으로 떨어지는 진행 값에 따른 가상의 3D 투시 계산식을 반환.
        p가 1.0일 때, y는 정확히 판정선(self.sh * 420/480)에 도달합니다.
        """
        hit_ratio = config.HIT_LINE_Y / 480.0
        
        # 2차 곡선을 적용하여, 위에서는 천천히, 아래로 올수록 빠르게 떨어지는 원근감 연출
        p_proj = p ** 2.0
        y = self.sh * hit_ratio * p_proj
        
        # 트랙 너비도 화면 y 좌표 위치(p_proj)에 비례해서 늘어나야만 
        # 양옆 레인 선이 휘어지지 않고 완벽한 직선(사다리꼴)을 유지합니다.
        top_w = self.sw * 0.20
        bottom_w = self.sw * 0.85
        w = top_w + (bottom_w - top_w) * p_proj
        
        return y, w

    def _get_lane_x(self, lane, w, total_lanes=4):
        """4분할된 특정 레인 폭과 x축 시작 위치 연산"""
        lane_w = w / total_lanes
        x = (self.sw / 2) - (w / 2) + (lane * lane_w)
        return x, lane_w

    def _add_judgment(self, text, color, combo=0, added_score=0):
        """판정 성공 시 화면 상단 텍스트 및 콤보 UI 버블 팝업 메시지를 쌓습니다."""
        self.judgments.append({
            "text": text,
            "color": color,
            "spawn_time": self.time,
            "duration": 0.7,
            "combo": combo,
            "added_score": added_score,
        })

    # --------------------------------------------------------
    # 이벤트 처리 및 업데이트 
    # --------------------------------------------------------
    def handle_event(self, event):
        """
        컴퓨터 키보드를 눌렀을 때의 조작(A,S,D,F 혹은 ESC) 
        """
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                pygame.mixer.music.stop()
                self.next_screen = "select"
            else:
                for i, key in enumerate(self.keys):
                    if event.key == key:
                        self.key_states[i] = True
                        self.key_glows[i] = 1.0  # 바닥 타일 하이라이트를 최대로 점등
                        self.last_lane = i

        elif event.type == pygame.KEYUP:
            for i, key in enumerate(self.keys):
                if event.key == key:
                    self.key_states[i] = False

    def handle_trigger(self, event):
        """
        UART 7바이트 패킷에서 추출된 딕셔너리 이벤트를 처리합니다.
        (파이썬 엣지 디텍션 없이 날아오는 패킷 1회당 즉각적인 UI 업데이트)
        """
        if not isinstance(event, dict):
            return
            
        # 1. State 동기화 (FPGA -> PC 화면 전환)
        fpga_state = event.get("state", 0)
        if fpga_state == config.READY and self.state != "COUNTDOWN_START":
            self.state = "COUNTDOWN_START"
            self.countdown_time = 3.0
        elif fpga_state == config.GAME_CONT and self.state != "PLAYING":
            self.state = "PLAYING"
            # 리드인 시스템으로 인해 여기서 음악을 재생하지 않고, update() 루프 내에서 play_time이 0이 될 때 재생합니다.
            
        # 2. 버튼 입력 시 해당 레인 하이라이트 (Left=0, Up=1, Down=2, Right=3)
        if event.get("left"):
            self.key_glows[0] = 1.0
            self.last_lane = 0
        if event.get("up"):
            self.key_glows[1] = 1.0
            self.last_lane = 1
        if event.get("down"):
            self.key_glows[2] = 1.0
            self.last_lane = 2
        if event.get("right"):
            self.key_glows[3] = 1.0
            self.last_lane = 3

        # 3. 판정 신호 수신 시 이펙트 폭발 및 점수 동기화
        #    판정선 근처에 있는 노트의 레인을 찾아서 이펙트 표시
        active_lanes = []
        for note in self.notes:
            if note.is_hit or note.is_missed:
                continue
            p = note.get_progress(self.time)
            # 판정선(1.0) 근처 ±0.15 범위의 노트 레인 수집
            if abs(p - self.hit_line_progress) < 0.15:
                if note.lane not in active_lanes:
                    active_lanes.append(note.lane)
        if not active_lanes:
            active_lanes = [getattr(self, "last_lane", 0)]

        hit_y, hit_w = self._get_projection(self.hit_line_progress)

        if event.get("perfect"):
            for lane in active_lanes:
                hit_x, hit_lw = self._get_lane_x(lane, hit_w)
                px = hit_x + hit_lw / 2
                
                # 피버 모드일 때 파티클 개수 대폭 증가 (화려하게)
                p_count = 45 if getattr(self, "fever", False) else 15
                for _ in range(p_count):
                    self.hit_particles.append(HitParticle(px, hit_y, C_NOTE_COLORS[lane]))
            flash_x = (self.sw - hit_w) / 2 + hit_w / 2
            self.hit_flashes.append(HitFlash(flash_x, hit_y, int(hit_w), C_NOTE_COLORS[active_lanes[0]], is_perfect=True))
            self._add_judgment("PERFECT!", COLOR_NEON_CYAN, event.get("combo", 0), 0)
            
        elif event.get("good"):
            for lane in active_lanes:
                hit_x, hit_lw = self._get_lane_x(lane, hit_w)
                px = hit_x + hit_lw / 2
                
                # 피버 모드일 때 파티클 개수 증가
                p_count = 24 if getattr(self, "fever", False) else 8
                for _ in range(p_count):
                    self.hit_particles.append(HitParticle(px, hit_y, C_NOTE_COLORS[lane]))
            self.hit_flashes.append(HitFlash(px, hit_y, int(hit_lw), C_NOTE_COLORS[active_lanes[0]], is_perfect=False))
            self._add_judgment("GOOD", (255, 200, 0), event.get("combo", 0), 0)
            
        elif event.get("miss"):
            self._add_judgment("MISS", (255, 50, 50), 0, 0)
            
        # FPGA의 점수/콤보로 무조건 덮어쓰기 (강력한 동기화)
        if "score" in event:
            self.score = event["score"]
        if "combo" in event:
            self.combo = event["combo"]
            self.max_combo = max(self.max_combo, self.combo)
        if "fever" in event:
            self.fever = event["fever"]

    def update(self, dt):
        """
        게임 진행 상황(시간, 점수 게이지, 이펙트 남은 수명, 노트 이동) 등 모든
        가상 세계의 물리 시뮬레이션을 프레임당 업데이트합니다.
        """
        self.time += dt

        # 수신된 이벤트(1프레임)로 켜진 레인 불빛을 매 프레임 서서히 끔 (시각적 펄스 효과)
        for i in range(4):
            if self.key_glows[i] > 0:
                self.key_glows[i] = max(0.0, self.key_glows[i] - dt * 4.0)

        # 피버 효과 서서히 점멸
        if getattr(self, "fever", False):
            self.fever_glow = min(1.0, getattr(self, "fever_glow", 0.0) + dt * 2.0)
        else:
            self.fever_glow = max(0.0, getattr(self, "fever_glow", 0.0) - dt * 2.0)

        # COUNTDOWN_START 상태는 이제 사용하지 않으므로 제거합니다.
        if self.state == "PLAYING":
            prev_play_time = self.play_time
            
            # 음악 시작 조건 체크
            if getattr(self, 'music_needs_start', False) and self.play_time >= 0.0:
                if getattr(self, 'music_loaded', False):
                    pygame.mixer.music.play()
                self.music_needs_start = False
                
            # 음악이 재생 중일 때는 파이썬 frame dt 대신 오디오 하드웨어의 재생 시간을 기준으로 싱크를 맞춥니다.
            if pygame.mixer.music.get_busy() and self.play_time >= 0.0:
                audio_pos = pygame.mixer.music.get_pos() / 1000.0
                if audio_pos > 0:
                    self.play_time = audio_pos
            else:
                self.play_time += dt
            
            # 리드인(Lead-in) 타이머가 0을 돌파하는 순간 정확히 음악 재생
            if prev_play_time < 0.0 and self.play_time >= 0.0:
                if getattr(self, 'music_loaded', False):
                    pygame.mixer.music.play()
            
            # 대기 중인 TX 노트 스케줄링 처리
            while self.pending_tx_notes and self.play_time >= self.pending_tx_notes[0]["spawn_time"]:
                p_note = self.pending_tx_notes.pop(0)
                
                # UART TX 전송 (가장 먼저 실행되어 FPGA는 0ms 딜레이로 즉각 출발)
                if self.send_tx:
                    self.send_tx(p_note["lane_val"])
                    print(f"[UART TX] 곡: {config.SONG_LIST[config.SELECTED_SONG_INDEX]['title']} | 전송시간: {self.play_time:.2f}s | 레인(Hex): {p_note['lane_val']:02X} | 타겟타임: {p_note['spawn_time']:.2f}s")
                    
                # UI 파이썬 노트 스폰 
                # (오디오 버퍼링 딜레이 + 파이썬 OS 모니터 출력 지연 보상)
                loop_delay = self.play_time - p_note["spawn_time"]
                actual_spawn_time = self.time - loop_delay - config.UI_RENDER_LATENCY
                actual_hit_time = actual_spawn_time + config.NOTE_SPEED
                for lane in p_note["lanes"]:
                    self.notes.append(Note(lane, actual_spawn_time, actual_hit_time))
                    
            # 마지막 노트 판정 라인 도달 시 완료 신호(0xF0) 전송
            if self.last_note_hit_time is not None and not self.done_signal_sent:
                if self.play_time >= self.last_note_hit_time:
                    if self.send_tx:
                        self.send_tx(0xF0)
                        print(f"[UART TX] 노래 종료 Done 신호 전송 (0xF0) - 타겟타임: {self.last_note_hit_time:.2f}s")
                    self.done_signal_sent = True
            
            # 내려오는 노트들의 진척도 확인
            active_notes = []
            for note in self.notes:
                if note.is_hit or note.is_missed:
                    continue

                p = note.get_progress(self.time)
                # 시야를 벗어난 경우 청소 (Miss 처리는 FPGA에서 하므로 여기선 시각적 삭제만)
                if p > self.hit_line_progress + 0.15:  
                    note.is_missed = True
                    continue

                active_notes.append(note)
            self.notes = active_notes


        # 유효시간이 다 지난 팝업 텍스트들은 자동 소거시킴 
        self.judgments = [j for j in self.judgments if self.time - j["spawn_time"] < j["duration"]]

        # 입자 그래픽 처리 
        self.hit_particles = [p for p in self.hit_particles if p.update(dt)]
        self.hit_flashes = [f for f in self.hit_flashes if f.update(dt)]

        # 배경 선분 무한 스크롤 착시 
        self.grid_scroll = (self.grid_scroll + dt * 0.5) % 1.0

        # UI 스코어 보드의 부드러운 애니메이션 차익 가산 연산 
        if self.score_display < self.score:
            diff = self.score - self.score_display
            self.score_display += max(1, int(diff * dt * 8))
            if self.score_display > self.score:
                self.score_display = self.score

        if self.score_pulse > 0:
            self.score_pulse = max(0.0, self.score_pulse - dt * 3.0)

        if self.combo_bounce > 0:
            self.combo_bounce = max(0.0, self.combo_bounce - dt * 5.0)

        if self.combo != self.prev_combo:
            if self.combo > self.prev_combo:
                self.combo_bounce = 1.0
                self.score_pulse = 1.0
            self.prev_combo = self.combo

    # --------------------------------------------------------
    # 물리적 화면 렌더링 
    # --------------------------------------------------------
    def _draw_track(self):
        self.screen.blit(self._bg_surface, (0, 0))
        for star in self.bg_stars:
            pulse = 0.5 + 0.5 * math.sin(self.time * star["pulse_speed"] + star["pulse_offset"])
            if pulse > 0.3:
                pygame.draw.circle(self.screen, (200, 210, 255), (star["x"], star["y"]), star["size"])
        self.screen.blit(self._track_border, (0, 0))
        self.screen.blit(self._track_base, (0, 0))
        
        any_glow = any(g > 0 for g in self.key_glows)
        if any_glow:
            self._track_overlay.fill((0, 0, 0, 0))
            segments = 25
            for i in range(segments):
                p1, p2 = i / segments, (i + 1) / segments
                y1, w1 = self._get_projection(p1)
                y2, w2 = self._get_projection(p2)
                for lane in range(4):
                    if self.key_glows[lane] <= 0: continue
                    x1, lw1 = self._get_lane_x(lane, w1)
                    x2, lw2 = self._get_lane_x(lane, w2)
                    pygame.draw.polygon(self._track_overlay, (*C_NOTE_COLORS[lane], min(255, int(80 * self.key_glows[lane]))), [(x1, y1), (x1+lw1, y1), (x2+lw2, y2), (x2, y2)])
            self.screen.blit(self._track_overlay, (0, 0))
        self.screen.blit(self._lane_lines, (0, 0))
        self._track_overlay.fill((0, 0, 0, 0))
        for gi in range(12):
            gp = ((gi / 12) + self.grid_scroll) % 1.0
            gy, gw = self._get_projection(gp)
            gx_start = (self.sw - gw) / 2
            alpha = int(25 * gp)
            if alpha > 3:
                pygame.draw.line(self._track_overlay, (*C_GRID_LINE[:3], alpha), (int(gx_start), int(gy)), (int(gx_start + gw), int(gy)), 1)
        
        fever_glow = getattr(self, "fever_glow", 0.0)
        # 피버 배경 노란색 폴리곤 비활성화 (요청)
        # if fever_glow > 0:
        #     y1, w1 = self._get_projection(0)
        #     y2, w2 = self._get_projection(1.0)
        #     fx1 = (self.sw - w1) / 2
        #     fx2 = (self.sw - w2) / 2
        #     pygame.draw.polygon(self._track_overlay, (255, 200, 50, int(50 * fever_glow)), 
        #                       [(fx1, y1), (fx1+w1, y1), (fx2+w2, y2), (fx2, y2)])
                              
        self.screen.blit(self._track_overlay, (0, 0))
        self.screen.blit(self._hitline_surface, (0, 0))
        
        # 판정선 위의 다이아몬드 아이콘 표시
        hit_y, hit_w = self._get_projection(self.hit_line_progress)
        for lane in range(4):
            mx, _ = self._get_lane_x(lane, hit_w)
            mx += hit_w / 8
            my = self._hitline_y
            
            if self.key_glows[lane] > 0:
                dia_color = C_NOTE_COLORS[lane]
                dia_size = 7
            else:
                dia_color = (100, 80, 140)
                dia_size = 5
                
            pts = [(mx, my - dia_size), (mx + dia_size, my),
                   (mx, my + dia_size), (mx - dia_size, my)]
            pygame.draw.polygon(self.screen, dia_color, pts)

    def _draw_notes(self):
        """가상 위치 정보를 가져와 모니터 픽셀에 맞게 화면의 크기를 키워 그립니다."""
        for note in self.notes:
            p = note.get_progress(self.time)
            if p < 0:
                continue

            actual_p = p * self.hit_line_progress
            y, w = self._get_projection(actual_p)
            x, lw = self._get_lane_x(note.lane, w)
            
            margin = lw * 0.08
            nx = int(x + margin)
            nw = int(lw - margin * 2)
            
            # 노트의 두께(굵기)를 너비에 비례하도록 3D 스케일링 적용
            # 이렇게 하면 위에서는 길쭉하고 아래서는 납작해보이는 왜곡 없이 항상 일정한 굵기 비율을 유지합니다.
            note_h = max(4, int(nw * 0.15))
            
            ny = int(y - note_h / 2)
            color = C_NOTE_COLORS[note.lane]
            radius = max(1, int(note_h / 2))

            if nw > 0 and note_h > 0:
                note_rect = pygame.Rect(nx, ny, nw, note_h)
                pygame.draw.rect(self.screen, color, note_rect, border_radius=radius)

                h_margin = max(2, int(note_h * 0.15))
                hl_rect = pygame.Rect(nx + 2, ny + h_margin, max(1, nw - 4), max(1, note_h - h_margin * 2))
                bright_color = (
                    min(255, color[0] + 80),
                    min(255, color[1] + 80),
                    min(255, color[2] + 80),
                )
                if hl_rect.width > 0 and hl_rect.height > 0:
                    pygame.draw.rect(self.screen, bright_color, hl_rect,
                                   border_radius=max(1, int(note_h / 3)))

    def _draw_hit_particles(self):
        """이펙트 오브젝트 표출 위임 함수"""
        for flash in self.hit_flashes:
            flash.draw(self.screen)
        for particle in self.hit_particles:
            particle.draw(self.screen)

    def _draw_ui(self):
        """모서리 및 상단 중앙 등에 스코어 텍스트, 키보드 조작 가이드 안내서 등을 출력합니다."""
        cx = self.sw // 2
        cy = self.sh // 2

        # 1. 왼쪽 위 점수판 
        panel_w = int(self.sw * 0.22)
        panel_h = int(self.sh * 0.11)
        panel_x = 16
        panel_y = 12

        panel_surf = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        pygame.draw.rect(panel_surf, (10, 5, 30, 140), (0, 0, panel_w, panel_h), border_radius=10)
        
        if self.score_pulse > 0:
            glow_alpha = int(180 * self.score_pulse)
            pygame.draw.rect(panel_surf, (*COLOR_NEON_CYAN[:3], glow_alpha),
                           (0, 0, panel_w, panel_h), width=2, border_radius=10)
        else:
            pygame.draw.rect(panel_surf, (60, 40, 100, 80),
                           (0, 0, panel_w, panel_h), width=1, border_radius=10)
                           
        self.screen.blit(panel_surf, (panel_x, panel_y))
        score_label = self.font_score_label.render("SCORE", True, (100, 200, 220))
        self.screen.blit(score_label, (panel_x + 12, panel_y + 8))

        if self.score_pulse > 0.3:
            pulse_color = (
                min(255, COLOR_NEON_CYAN[0] + int(100 * self.score_pulse)),
                min(255, COLOR_NEON_CYAN[1] + int(50 * self.score_pulse)),
                min(255, COLOR_NEON_CYAN[2] + int(30 * self.score_pulse)),
            )
        else:
            pulse_color = COLOR_NEON_CYAN
            
        score_text = self.font_score.render(f"{self.score_display:07d}", True, pulse_color)
        self.screen.blit(score_text, (panel_x + 12, panel_y + 26))

        # 2. 키 가이드라인 (사용하지 않으므로 제거됨)

        # 3. 중앙 콤보 / 판정 글씨 팝업
        for j in self.judgments:
            age = self.time - j["spawn_time"]
            ratio = age / j["duration"]

            anim_y = cy - int(self.sh * 0.12) - int(40 * ratio)

            if ratio < 0.15:
                scale = 1.0 + 0.8 * (1.0 - ratio / 0.15)
            elif ratio < 0.3:
                scale = 1.0 + 0.1 * math.sin((ratio - 0.15) / 0.15 * math.pi)
            else:
                scale = 1.0

            judge_surf = self.font_judge.render(j["text"], True, j["color"])

            alpha = int(255 * (1.0 - max(0, (ratio - 0.5)) * 2.0))
            alpha = max(0, min(255, alpha))
            judge_surf.set_alpha(alpha)

            if scale != 1.0:
                new_w = int(judge_surf.get_width() * scale)
                new_h = int(judge_surf.get_height() * scale)
                if new_w > 0 and new_h > 0:
                    judge_surf = pygame.transform.scale(judge_surf, (new_w, new_h))

            self.screen.blit(judge_surf, judge_surf.get_rect(center=(cx, anim_y)))

            combo_val = j.get("combo", 0)
            if combo_val > 0:
                sub_y = anim_y + int(self.sh * 0.055)
                sub_text = f"+{combo_val} COMBO"

                if combo_val >= 30:
                    sub_color = (255, 180, 0)
                elif combo_val >= 10:
                    sub_color = COLOR_NEON_CYAN
                else:
                    sub_color = (180, 180, 200)

                sub_surf = self.font_combo_label.render(sub_text, True, sub_color)
                sub_surf.set_alpha(alpha)
                self.screen.blit(sub_surf, sub_surf.get_rect(center=(cx, sub_y)))

        # 4. 피버 상태 표시 텍스트
        fever_glow = getattr(self, "fever_glow", 0.0)
        if fever_glow > 0:
            fever_scale = 1.0 + 0.1 * math.sin(self.time * 15)
            fever_surf = self.font_judge.render("FEVER!!", True, (255, 220, 50))
            fw, fh = fever_surf.get_width(), fever_surf.get_height()
            new_fw, new_fh = int(fw * fever_scale), int(fh * fever_scale)
            if new_fw > 0 and new_fh > 0:
                scaled_fever = pygame.transform.smoothscale(fever_surf, (new_fw, new_fh))
                scaled_fever.set_alpha(int(255 * fever_glow))
                self.screen.blit(scaled_fever, scaled_fever.get_rect(center=(cx, cy - int(self.sh * 0.25))))

    def _draw_countdown(self):
        """게임 시작 전 혹은 종료 후의 카운트다운을 화면에 그립니다."""
        if self.state == "PLAYING":
            return
            
        text = ""
        pulse = 1.0
        
        if self.state == "COUNTDOWN_START":
            if self.countdown_time > 1.0:
                text = str(int(self.countdown_time))
                pulse = self.countdown_time - int(self.countdown_time)
            elif self.countdown_time > 0:
                text = "START!"
                pulse = self.countdown_time
                

                
        if not text:
            return
            
        cx = self.sw // 2
        cy = self.sh // 2 - int(self.sh * 0.1)
        
        size_scale = 1.0 + (1.0 - pulse) * 1.5
        alpha = int(255 * pulse)
        
        base_surf = self.font_judge.render(text, True, COLOR_NEON_CYAN)
        scaled_w = int(base_surf.get_width() * size_scale)
        scaled_h = int(base_surf.get_height() * size_scale)
        
        if scaled_w > 0 and scaled_h > 0:
            scaled_surf = pygame.transform.smoothscale(base_surf, (scaled_w, scaled_h))
            
            alpha_surf = pygame.Surface((scaled_w, scaled_h), pygame.SRCALPHA)
            alpha_surf.blit(scaled_surf, (0, 0))
            alpha_surf.set_alpha(alpha)
            
            rect = alpha_surf.get_rect(center=(cx, cy))
            self.screen.blit(alpha_surf, rect)

    def draw(self):
        self._draw_track()
        self._draw_notes()
        self._draw_hit_particles()
        self._draw_ui()
        self._draw_countdown()
        self.screen.blit(self._scanline_surface, (0, 0))
