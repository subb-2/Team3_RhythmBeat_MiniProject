# -*- coding: utf-8 -*-
"""
시작 화면 (Start Screen) 모듈

게임이 처음 켜질 때 표시되는 화면입니다.
실제 게임 플레이 장면을 배경으로 사용하며, 그 위에 떠다니는 파티클,
타이틀 로고, 그리고 'PRESS START' 펄스 애니메이션을 오버레이로 표시합니다.

주요 구성 요소:
- StartScreen: 메인 화면 클래스 (상태 초기화, 렌더링, 이벤트 처리)
- DemoNote: 배경에서 자동으로 내려오는 가짜 노트 (장식용)
- Particle: 화면 전체를 떠다니는 빛 입자 효과 (장식용)
"""

import pygame
import math
import random

from screens.base_screen import BaseScreen
from config import (
    COLOR_BG_DARK, COLOR_BG_NAVY,
    COLOR_NEON_CYAN, COLOR_NEON_PINK, COLOR_NEON_PURPLE, COLOR_NEON_BLUE,
    COLOR_WHITE, COLOR_GRAY, COLOR_TEXT_DIM,
    PARTICLE_COUNT, PARTICLE_MIN_SIZE, PARTICLE_MAX_SIZE,
    PARTICLE_MIN_SPEED, PARTICLE_MAX_SPEED,
)

# ============================================================
# 색상 상수
# ============================================================
# 게임 화면과 시각적 통일감을 주기 위해 동일한 색상 팔레트 사용
C_BG_GAME = (8, 4, 28)            # 깊은 남색 배경 (트랙 배경)
C_BG_GRADIENT = (20, 8, 48)       # 그라데이션 하단 (부드러운 퍼플)
C_LANE_BG = (25, 12, 55)          # 레인 폴리곤 배경 (불투명)
C_LANE_LINE = (60, 30, 120)       # 레인 사이의 구분선 색상
C_LANE_GLOW = (0, 200, 255)       # 레인 활성화 시 글로우 색상
C_HIT_LINE = (255, 100, 200)      # 하단 판정선 색상 (핑크)
C_GRID_LINE = (30, 15, 70)        # 배경을 스크롤하는 가로 그리드 선

# 레인 4개(A, S, D, F) 각각에 대응하는 색상
C_NOTE_COLORS = [
    (0, 220, 255),    # 레인 0 - 시안
    (255, 50, 180),   # 레인 1 - 핑크
    (180, 80, 255),   # 레인 2 - 퍼플
    (50, 255, 150),   # 레인 3 - 그린
]


# ============================================================
# 이펙트 클래스
# ============================================================
class DemoNote:
    """
    데모용 자동 노트 클래스
    
    타이틀 화면 배경에서 자동으로 생성되어 판정선을 향해 내려가는 시각적 효과용 노트입니다.
    실제 판정 로직은 없습니다.
    """

    def __init__(self, lane, spawn_time, speed):
        """
        초기화
        
        Args:
            lane (int): 노트가 스폰될 레인 인덱스 (0~3)
            spawn_time (float): 노트가 생성된 시간 (초)
            speed (float): 노트가 판정선에 도달하기까지 걸리는 시간 (초)
        """
        self.lane = lane
        self.spawn_time = spawn_time
        self.speed = speed

    def get_progress(self, current_time):
        """
        현재 시간에 따른 노트의 진행도를 0.0 ~ 1.0 비율로 계산합니다.
        
        Args:
            current_time (float): 현재 게임 경과 시간 (초)
            
        Returns:
            float: 진행 비율. 0.0(스폰 시점) ~ 1.0(판정선 통과). 1.0 이상이면 판정선을 넘어간 것.
        """
        elapsed = current_time - self.spawn_time
        return elapsed / self.speed


class Particle:
    """
    배경 파티클 클래스
    
    화면 전체를 부유하는 반투명한 빛 입자를 표현합니다.
    """

    def __init__(self, sw, sh):
        """
        초기화
        
        Args:
            sw (int): 화면 너비
            sh (int): 화면 높이
        """
        self.sw = sw
        self.sh = sh
        self.reset()

    def reset(self):
        """파티클의 위치, 크기, 속도, 색상, 알파값을 무작위로 초기화합니다."""
        self.x = random.randint(0, self.sw)
        self.y = random.randint(0, self.sh)
        self.size = random.uniform(PARTICLE_MIN_SIZE, PARTICLE_MAX_SIZE)
        self.speed_x = random.uniform(-PARTICLE_MIN_SPEED, PARTICLE_MIN_SPEED)
        self.speed_y = random.uniform(-PARTICLE_MAX_SPEED, -PARTICLE_MIN_SPEED)
        self.alpha = random.randint(40, 160)
        
        # 4가지 네온 색상 중 하나 무작위 선택
        self.color_base = random.choice([
            COLOR_NEON_CYAN, COLOR_NEON_PINK, COLOR_NEON_PURPLE, COLOR_NEON_BLUE
        ])
        
        # 반짝이는 효과를 위한 펄스(사인파) 매개변수
        self.pulse_speed = random.uniform(1.0, 3.0)
        self.pulse_offset = random.uniform(0, math.pi * 2)

    def update(self, dt, time):
        """
        파티클의 위치와 투명도를 프레임 간 경과 시간(dt)에 맞추어 갱신합니다.
        화면 밖으로 나갈 경우 반대편에서 재등장시킵니다.
        """
        # 60 픽셀/초 기준으로 이동 속도 적용
        self.x += self.speed_x * dt * 60
        self.y += self.speed_y * dt * 60

        # y축: 화면 위로 나가면 아래로 재배치
        if self.y < -10:
            self.y = self.sh + 10
            self.x = random.randint(0, self.sw)
            
        # x축: 화면 양 끝으로 나가면 반대편으로 재배치
        if self.x < -10:
            self.x = self.sw + 10
        elif self.x > self.sw + 10:
            self.x = -10

        # 시간(time) 흐름에 따라 알파값이 주기적으로 변하도록(깜빡이도록) 사인파 적용
        self.current_alpha = int(
            self.alpha * (0.5 + 0.5 * math.sin(time * self.pulse_speed + self.pulse_offset))
        )

    def draw(self, surface):
        """
        파티클을 지정된 surface 객체에 렌더링합니다.
        작은 코어 중심에 옅은 글로우가 퍼지도록 그립니다.
        """
        if self.current_alpha > 10:
            # 외부 글로우 렌더링 (흐리고 크게)
            glow_surf = pygame.Surface((int(self.size * 8), int(self.size * 8)), pygame.SRCALPHA)
            glow_color = (*self.color_base[:3], min(self.current_alpha // 3, 80))
            pygame.draw.circle(
                glow_surf, glow_color,
                (int(self.size * 4), int(self.size * 4)),
                int(self.size * 4)
            )
            surface.blit(
                glow_surf,
                (int(self.x - self.size * 4), int(self.y - self.size * 4))
            )

            # 내부 코어 렌더링 (진하고 작게)
            core_color = (*self.color_base[:3], min(self.current_alpha, 255))
            core_surf = pygame.Surface((int(self.size * 4), int(self.size * 4)), pygame.SRCALPHA)
            pygame.draw.circle(
                core_surf, core_color,
                (int(self.size * 2), int(self.size * 2)),
                int(self.size)
            )
            surface.blit(
                core_surf,
                (int(self.x - self.size * 2), int(self.y - self.size * 2))
            )


# ============================================================
# 메인 클래스
# ============================================================
class StartScreen(BaseScreen):
    """
    게임 시작 화면 클래스
    
    사용자 입력을 대기하며, 입력이 들어오면 다음 화면('select')으로 전환을 요청합니다.
    시각적 만족을 위해 뒷배경에서는 가짜 노트가 투시를 적용받으며 떨어집니다.
    """

    # --------------------------------------------------------
    # 초기화
    # --------------------------------------------------------
    def __init__(self, screen, clock):
        """
        인스턴스 생성 시 변수들을 초기화하고 캐싱용 리소스들을 미리 만듭니다.
        """
        super().__init__(screen, clock)
        self.time = 0.0

        # 화면 해상도 저장
        self.sw = screen.get_width()
        self.sh = screen.get_height()

        # 배경 파티클 생성
        self.particles = [Particle(self.sw, self.sh) for _ in range(PARTICLE_COUNT)]

        # 폰트 초기화
        self._init_fonts()

        # 3D 투시 관점(y좌표 85% 지점을 판정선으로 둠)
        self.hit_line_progress = 0.85

        # 배경을 장식할 정적 별 무리(단순한 원 렌더링용 정보 모음)
        self.bg_stars = []
        for _ in range(30):
            self.bg_stars.append({
                "x": random.randint(0, self.sw),
                "y": random.randint(0, self.sh),
                "size": random.randint(1, 2),
                "pulse_speed": random.uniform(1.0, 3.0),
                "pulse_offset": random.uniform(0, math.pi * 2),
            })

        # 가로 그리드 라인이 서서히 다가오는 효과용 스크롤 누적값
        self.grid_scroll = 0.0

        # 데모 노트 관리 배열 및 생성 관련 타이머 변수
        self.demo_notes = []
        self.next_note_time = 0.5
        self.note_speed = 1.8  # 노트 낙하 시간(초)

        # 렌더링 부하를 줄이기 위해 변하지 않는 그래픽(배경, 선 등)은 Surface로 미리 렌더링
        self._init_cached_surfaces()

    # --------------------------------------------------------
    # 캐싱 및 유틸리티
    # --------------------------------------------------------
    def _init_cached_surfaces(self):
        """
        매 프레임 직접 그리기엔 무거운 배경/그라데이션/라인 등을
        Surface 객체로 단 한 번 미리 렌더링하여 메모리에 들고 있도록 캐싱합니다.
        """
        # 1. 배경 그라데이션 캐싱
        self._bg_surface = pygame.Surface((self.sw, self.sh))
        for y in range(0, self.sh, 2):
            ratio = y / self.sh
            r = int(C_BG_GAME[0] * (1 - ratio) + C_BG_GRADIENT[0] * ratio)
            g = int(C_BG_GAME[1] * (1 - ratio) + C_BG_GRADIENT[1] * ratio)
            b = int(C_BG_GAME[2] * (1 - ratio) + C_BG_GRADIENT[2] * ratio)
            pygame.draw.rect(self._bg_surface, (r, g, b), (0, y, self.sw, 2))

        # 2. 브라운관 TV 느낌의 스캔라인 오버레이 캐싱
        self._scanline_surface = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        for y in range(0, self.sh, 3):
            pygame.draw.line(self._scanline_surface, (0, 0, 0, 20), (0, y), (self.sw, y), 1)

        # 3. 그리기 덧대기용 빈 투명 레이어
        self._track_overlay = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)

        # 4. 트랙 가장자리(외곽선) 캐싱 (원근감 적용 선 긋기)
        self._track_border = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        _, top_w = self._get_projection(0)
        _, bot_w = self._get_projection(1.0)
        top_lx = (self.sw - top_w) / 2
        top_rx = top_lx + top_w
        bot_lx = (self.sw - bot_w) / 2
        bot_rx = bot_lx + bot_w
        for gi in range(4):
            alpha = max(0, 60 - gi * 15)
            # 좌측 선
            pygame.draw.line(self._track_border, (*COLOR_NEON_PURPLE[:3], alpha),
                           (int(top_lx) - gi, 0), (int(bot_lx) - gi, self.sh), 1)
            # 우측 선
            pygame.draw.line(self._track_border, (*COLOR_NEON_PURPLE[:3], alpha),
                           (int(top_rx) + gi, 0), (int(bot_rx) + gi, self.sh), 1)

        # 5. 레인(4칸) 구분선 캐싱
        self._lane_lines = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        segments = 25
        for i in range(segments):
            p1 = i / segments
            p2 = (i + 1) / segments
            y1, w1 = self._get_projection(p1)
            y2, w2 = self._get_projection(p2)
            # 상단일수록 선명하고 하단일수록 밝아지게 계산
            line_alpha = min(255, int(240 + 160 * (p1 ** 0.5)))
            for lane in range(4):
                x1, lw1 = self._get_lane_x(lane, w1)
                x2, lw2 = self._get_lane_x(lane, w2)
                # 세로선 긋기
                pygame.draw.line(self._lane_lines, (*C_LANE_LINE[:3], line_alpha),
                               (int(x1), int(y1)), (int(x2), int(y2)), 3)
                # 맨 우측 테두리는 3번 레인의 끝부분을 그어줌
                if lane == 3:
                    pygame.draw.line(self._lane_lines, (*C_LANE_LINE[:3], line_alpha),
                                   (int(x1 + lw1), int(y1)), (int(x2 + lw2), int(y2)), 3)

        # 6. 타격 위치 판정선 영역 캐싱
        hit_y, hit_w = self._get_projection(self.hit_line_progress)
        hit_x, _ = self._get_lane_x(0, hit_w)
        self._hitline_surface = pygame.Surface((self.sw, 50), pygame.SRCALPHA)
        
        # 겹겹이 두꺼운 선을 그어 번짐 효과
        for gi in range(8):
            alpha = max(0, 50 - gi * 6)
            pygame.draw.line(self._hitline_surface, (*C_HIT_LINE[:3], alpha),
                           (int(hit_x), 25 - gi), (int(hit_x + hit_w), 25 - gi), 1)
            pygame.draw.line(self._hitline_surface, (*C_HIT_LINE[:3], alpha),
                           (int(hit_x), 25 + gi), (int(hit_x + hit_w), 25 + gi), 1)
                           
        # 중심 밝은 선
        pygame.draw.line(self._hitline_surface, C_HIT_LINE,
                        (int(hit_x), 25), (int(hit_x + hit_w), 25), 3)
        pygame.draw.line(self._hitline_surface, (255, 200, 240),
                        (int(hit_x), 25), (int(hit_x + hit_w), 25), 1)
        self._hitline_y = hit_y

        # 7. 트랙 바닥 영역 폴리곤 캐싱 (단색 불투명)
        self._track_base = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        for i in range(segments):
            p1 = i / segments
            p2 = (i + 1) / segments
            y1, w1 = self._get_projection(p1)
            y2, w2 = self._get_projection(p2)
            for lane in range(4):
                x1, lw1 = self._get_lane_x(lane, w1)
                x2, lw2 = self._get_lane_x(lane, w2)
                pts = [(x1, y1), (x1 + lw1, y1), (x2 + lw2, y2), (x2, y2)]
                pygame.draw.polygon(self._track_base, (*C_LANE_BG, 100), pts)

        # 8. 백그라운드 위를 살짝 어둡게 덮어서 타이틀 글씨가 눈에 띄게 할 반투명 레이어
        self._title_overlay = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        self._title_overlay.fill((0, 0, 0, 100))

    def _get_projection(self, p):
        """
        가짜 3D 투시 계산. 0.0 ~ 1.0 비율(p) 값을 넘기면
        해당 진행도의 y 위치(높이)와 해당 위치에서의 트랙 총 너비를 반환합니다.
        
        Args:
            p (float): 0.0 ~ 1.0의 진행률 비율. 0은 트랙 꼭대기, 1.0은 바닥면.
            
        Returns:
            tuple: (y축 좌표 픽셀값, 너비 픽셀값)
        """
        # smoothstep 스타일 이징 공식을 합성하여 내려올수록 가속되는 자연스러운 3D 곡선 도출
        eased_p = p * p * (3.0 - 2.0 * p)
        eased_p = eased_p * 0.4 + (p ** 1.6) * 0.6

        y = self.sh * eased_p
        ratio = y / self.sh

        top_w = self.sw * 0.18
        bottom_w = self.sw * 0.85

        w = top_w + (bottom_w - top_w) * ratio
        return y, w

    def _get_lane_x(self, lane, w, total_lanes=4):
        """
        주어진 트랙 너비(w) 내에서 특정 레인의 시작 x좌표 픽셀값과 레인의 너비를 구합니다.
        
        Args:
            lane (int): 0~3 사이의 레인 번호.
            w (float): 현재 y축에서의 트랙 총 가로 너비
            total_lanes (int): 레인 총합 개수. 기본은 4.
            
        Returns:
            tuple: (레인의 좌측 x좌표, 1개 레인 폭 너비)
        """
        lane_w = w / total_lanes
        x = (self.sw / 2) - (w / 2) + (lane * lane_w)
        return x, lane_w

    def _init_fonts(self):
        """
        폰트 객체들을 초기화합니다.
        시스템 내에 한글 폰트가 있는지 순차 탐색하여 첫 번째로 맞는 것을 채택합니다.
        """
        korean_fonts = ["malgun gothic", "malgungothic", "gulim", "dotum", "batang"]
        font_name = None
        for fname in korean_fonts:
            if fname in [f.lower() for f in pygame.font.get_fonts()]:
                font_name = fname
                break

        # 창 크기에 비례하는 폰트 크기 계산 스케일 인자 (가변 해상도 대응용)
        scale = self.sh / 600.0
        
        if font_name:
            # 기본 타이틀용과 타이틀 글로우용 폰트를 미리 딕셔너리로 저장하여 재탐색을 막음
            self.font_title = pygame.font.SysFont(font_name, int(110 * scale), bold=True)
            self.font_title_glows = [
                pygame.font.SysFont(font_name, int(s * scale), bold=True)
                for s in [118, 114, 112, 110]
            ]
            self.font_press = pygame.font.SysFont(font_name, int(32 * scale), bold=True)
        else:
            self.font_title = pygame.font.Font(None, int(120 * scale))
            self.font_title_glows = [
                pygame.font.Font(None, int((s + 8) * scale))
                for s in [118, 114, 112, 110]
            ]
            self.font_press = pygame.font.Font(None, int(36 * scale))

    # --------------------------------------------------------
    # 데모 노트
    # --------------------------------------------------------
    def _spawn_demo_notes(self):
        """
        지정된 시간이 다가오면 0~3 랜덤한 레인에 가짜 노트를 만들고
        다음번 노트가 나올 시간을 다시 무작위로 스케줄링합니다.
        """
        if self.time >= self.next_note_time:
            lane = random.randint(0, 3)
            self.demo_notes.append(DemoNote(lane, self.time, self.note_speed))

            # 40% 확률로 다른 레인에 동시에 노트를 덧붙임 (동시치기 연출)
            if random.random() > 0.6:
                lane2 = random.randint(0, 3)
                if lane2 != lane:
                    self.demo_notes.append(DemoNote(lane2, self.time, self.note_speed))

            self.next_note_time = self.time + random.uniform(0.3, 0.7)

    # --------------------------------------------------------
    # 렌더링
    # --------------------------------------------------------
    def _draw_game_bg(self):
        """
        캐싱해 둔 그래픽 서피스들과 배경 별, 다이아몬드 아이콘, 그리고
        진행 중인 데모 노트 객체들을 화면에 순차적으로 겹쳐 그립니다.
        """
        # 1. 배경 서피스
        self.screen.blit(self._bg_surface, (0, 0))

        # 2. 직접 그리는 배경 별
        for star in self.bg_stars:
            pulse = 0.5 + 0.5 * math.sin(self.time * star["pulse_speed"] + star["pulse_offset"])
            if pulse > 0.3:
                pygame.draw.circle(self.screen, (200, 210, 255),
                                 (star["x"], star["y"]), star["size"])

        # 3. 트랙 테두리
        self.screen.blit(self._track_border, (0, 0))

        # 4. 트랙 레인 베이스
        self.screen.blit(self._track_base, (0, 0))

        # 5. 레인 구분선
        self.screen.blit(self._lane_lines, (0, 0))

        # 6. 속도감 상승을 위한 움직이는 수평 가로선 그리기 (재생용 투명 캔버스 재활용)
        self._track_overlay.fill((0, 0, 0, 0))
        for gi in range(12):
            # 시간이 지남에 따라 가로선이 0.0에서 1.0으로 밀림
            gp = ((gi / 12) + self.grid_scroll) % 1.0
            gy, gw = self._get_projection(gp)
            gx_start = (self.sw - gw) / 2
            alpha = int(25 * gp)  # 멀리 있을 땐 흐리고 다가올수록 선명
            if alpha > 3:
                pygame.draw.line(self._track_overlay, (*C_GRID_LINE[:3], alpha),
                               (int(gx_start), int(gy)),
                               (int(gx_start + gw), int(gy)), 1)
        self.screen.blit(self._track_overlay, (0, 0))

        # 7. 캐싱된 판정선 올리기
        self.screen.blit(self._hitline_surface, (0, int(self._hitline_y) - 25))

        # 8. 키 4개에 대응하는 다이아몬드 기호를 판정선 위에 그리기
        hit_y, hit_w = self._get_projection(self.hit_line_progress)
        hit_x, _ = self._get_lane_x(0, hit_w)
        for lane in range(4):
            mx = int(hit_x + (lane + 0.5) * hit_w / 4)
            my = int(hit_y)
            dia_color = (100, 80, 140)
            dia_size = 5
            pts = [(mx, my - dia_size), (mx + dia_size, my),
                   (mx, my + dia_size), (mx - dia_size, my)]
            pygame.draw.polygon(self.screen, dia_color, pts)

        # 9. 현재 이동 중인 모든 노트 위치에 맞게 사각형 출력
        self._draw_demo_notes()

    def _draw_demo_notes(self):
        """
        데모 노트 리스트를 순회하며 투시 공식을 활용해 각 노트의
        y위치와 그 지점의 레인 폭/너비를 계산하고 직사각형 바디와 코어광을 그립니다.
        """
        for note in self.demo_notes:
            p = note.get_progress(self.time)
            if p < 0:
                continue

            # 가상 공간 좌표를 렌더링 화면의 비율로 변환
            actual_p = p * self.hit_line_progress
            y, w = self._get_projection(actual_p)
            x, lw = self._get_lane_x(note.lane, w)

            # 아래로 향할수록 카메라에 가까워져 크게 보이도록 높이 계산
            note_h = max(4, int(self.sh * 0.035 * (0.3 + actual_p * 0.7)))

            color = C_NOTE_COLORS[note.lane]
            margin = lw * 0.08
            nx = int(x + margin)
            nw = int(lw - margin * 2)
            ny = int(y - note_h / 2)
            radius = max(1, int(note_h / 2))

            if nw > 0 and note_h > 0:
                # 메인 몸체 렌더링
                note_rect = pygame.Rect(nx, ny, nw, note_h)
                pygame.draw.rect(self.screen, color, note_rect, border_radius=radius)

                # 중앙이 더 하얗게 빛나보이는 코어 하이라이팅
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

    def _draw_title(self):
        """
        게임 메인 타이틀 로고를 반투명한 암막 위에 띄워 그리고,
        미리 지정해둔 글로우용 폰트를 여러번 겹쳐 퍼지는 네온사인 효과를 줍니다.
        """
        self.screen.blit(self._title_overlay, (0, 0))

        title_text = "RHYTHM BEAT"
        cx = self.sw // 2
        cy = self.sh // 2 - int(self.sh * 0.1)

        glow_alphas = [15, 30, 50, 255]

        # 저장된 font 목록과 알파값을 매치해가며 점진적으로 투명도를 올리면서 겹쳐 그림
        for i, (glow_font, alpha) in enumerate(zip(self.font_title_glows, glow_alphas)):
            if i < len(self.font_title_glows) - 1:
                text_surf = glow_font.render(title_text, True, COLOR_NEON_CYAN)
                glow_surf = pygame.Surface(
                    (text_surf.get_width() + 20, text_surf.get_height() + 20),
                    pygame.SRCALPHA
                )
                glow_surf.set_alpha(alpha)
                glow_surf.blit(text_surf, (10, 10))
                rect = glow_surf.get_rect(center=(cx, cy))
                self.screen.blit(glow_surf, rect)
            else:
                # 제일 안쪽 핵심 글씨 (흰색, 사이즈 가장 작음)
                text_surf = self.font_title.render(title_text, True, COLOR_WHITE)
                rect = text_surf.get_rect(center=(cx, cy))
                self.screen.blit(text_surf, rect)

    def _draw_press_start(self):
        """
        게임 진입을 유도하는 텍스트 렌더링.
        시간에 비례한 삼각함수 사인 곡선에 알파값을 곱해 밝아졌다 어두워지는 효과(펄스)를 연출합니다.
        """
        cx = self.sw // 2
        cy = self.sh // 2 + int(self.sh * 0.15)

        pulse = math.sin(self.time * 2.5)
        alpha = int(128 + 127 * pulse)

        text = "PRESS START"
        text_surf = self.font_press.render(text, True, COLOR_NEON_CYAN)

        # 둥근 버튼 형태 느낌의 글로우 뒷배경 틀을 준비
        glow_surf = pygame.Surface(
            (text_surf.get_width() + 30, text_surf.get_height() + 20),
            pygame.SRCALPHA
        )

        # 배경 채색
        glow_alpha = int(30 * (0.5 + 0.5 * pulse))
        pygame.draw.rect(
            glow_surf,
            (*COLOR_NEON_CYAN[:3], glow_alpha),
            (0, 0, glow_surf.get_width(), glow_surf.get_height()),
            border_radius=8
        )

        # 테두리 선 긋기
        border_alpha = int(80 * (0.5 + 0.5 * pulse))
        pygame.draw.rect(
            glow_surf,
            (*COLOR_NEON_CYAN[:3], border_alpha),
            (0, 0, glow_surf.get_width(), glow_surf.get_height()),
            width=2,
            border_radius=8
        )

        glow_rect = glow_surf.get_rect(center=(cx, cy))
        self.screen.blit(glow_surf, glow_rect)

        # 텍스트 레이어를 덮어씌움
        text_alpha_surf = pygame.Surface(
            (text_surf.get_width(), text_surf.get_height()),
            pygame.SRCALPHA
        )
        text_alpha_surf.blit(text_surf, (0, 0))
        text_alpha_surf.set_alpha(alpha)
        text_rect = text_alpha_surf.get_rect(center=(cx, cy))
        self.screen.blit(text_alpha_surf, text_rect)

    # --------------------------------------------------------
    # 이벤트 및 상태 업데이트
    # --------------------------------------------------------
    def handle_event(self, event):
        """
        사용자가 키보드 엔터/스페이스바를 누르거나 마우스 좌측 버튼 클릭 시
        다음 곡 선택 화면(select)으로 넘어가도록 플래그를 세웁니다.
        """
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_RETURN, pygame.K_SPACE, pygame.K_KP_ENTER, pygame.K_d):
                self.next_screen = "select"
        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                self.next_screen = "select"

    def handle_trigger(self, event):
        """
        파이썬 UI는 이제 FPGA state를 보고 화면을 전환하므로 버튼 신호에 의한 화면 전환은 무시합니다.
        """
        pass

    def update(self, dt):
        """
        매 프레임마다 경과된 델타 타임(dt)을 인계받아 시간, 파티클 좌표,
        스크롤 위치, 그리고 장식용 데모 노트의 생명 주기 등을 일제히 진행시킵니다.
        """
        self.time += dt

        # 파티클 업데이트
        for particle in self.particles:
            particle.update(dt, self.time)

        # 그물망 선 이동
        self.grid_scroll = (self.grid_scroll + dt * 0.5) % 1.0

        # 신규 데모 노트 생성
        self._spawn_demo_notes()

        # 판정선을 한참 지나 화면 시야 바닥 밑으로 꺼진 데모 노트를 리스트에서 제외 (메모리 관리)
        self.demo_notes = [
            n for n in self.demo_notes
            if n.get_progress(self.time) < 1.2
        ]

    def draw(self):
        """
        게임의 현재 프레임 화면 구성을 메인 서피스(self.screen)에 전부 순차적으로 렌더링합니다.
        가장 멀리, 혹은 아래쪽 층부터 겹쳐 그립니다.
        """
        self._draw_game_bg()
        self.screen.blit(self._scanline_surface, (0, 0))
        for particle in self.particles:
            particle.draw(self.screen)
        self._draw_title()
        self._draw_press_start()
