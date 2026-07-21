import pygame
import math
import random
import config
import leaderboard
from screens.base_screen import BaseScreen
from config import (
    COLOR_BG_DARK, COLOR_BG_NAVY,
    COLOR_NEON_CYAN, COLOR_NEON_PINK, COLOR_NEON_PURPLE, COLOR_NEON_BLUE,
    COLOR_WHITE, COLOR_GRAY, COLOR_TEXT_DIM,
    PARTICLE_COUNT, PARTICLE_MIN_SIZE, PARTICLE_MAX_SIZE,
    PARTICLE_MIN_SPEED, PARTICLE_MAX_SPEED,
)

class Particle:
    def __init__(self, sw, sh):
        self.sw = sw
        self.sh = sh
        self.reset()

    def reset(self):
        self.x = random.randint(0, self.sw)
        self.y = random.randint(0, self.sh)
        self.size = random.uniform(PARTICLE_MIN_SIZE, PARTICLE_MAX_SIZE)
        self.speed_x = random.uniform(-PARTICLE_MIN_SPEED, PARTICLE_MIN_SPEED)
        self.speed_y = random.uniform(-PARTICLE_MAX_SPEED, -PARTICLE_MIN_SPEED)
        self.alpha = random.randint(40, 160)
        self.color_base = random.choice([COLOR_NEON_CYAN, COLOR_NEON_PINK, COLOR_NEON_PURPLE])
        self.pulse_speed = random.uniform(1.0, 3.0)
        self.pulse_offset = random.uniform(0, math.pi * 2)
        self.current_alpha = 0

    def update(self, dt, time):
        self.x += self.speed_x * dt * 60
        self.y += self.speed_y * dt * 60
        if self.y < -10:
            self.y = self.sh + 10
            self.x = random.randint(0, self.sw)
        if self.x < -10:
            self.x = self.sw + 10
        elif self.x > self.sw + 10:
            self.x = -10
        self.current_alpha = int(self.alpha * (0.5 + 0.5 * math.sin(time * self.pulse_speed + self.pulse_offset)))

    def draw(self, surface):
        if self.current_alpha > 10:
            glow_surf = pygame.Surface((int(self.size * 8), int(self.size * 8)), pygame.SRCALPHA)
            glow_color = (*self.color_base[:3], min(self.current_alpha // 3, 80))
            pygame.draw.circle(glow_surf, glow_color, (int(self.size * 4), int(self.size * 4)), int(self.size * 4))
            surface.blit(glow_surf, (int(self.x - self.size * 4), int(self.y - self.size * 4)))
            
            core_color = (*self.color_base[:3], min(self.current_alpha, 255))
            core_surf = pygame.Surface((int(self.size * 4), int(self.size * 4)), pygame.SRCALPHA)
            pygame.draw.circle(core_surf, core_color, (int(self.size * 2), int(self.size * 2)), int(self.size))
            surface.blit(core_surf, (int(self.x - self.size * 2), int(self.y - self.size * 2)))

class ResultScreen(BaseScreen):
    """
    게임 결과 화면 및 리더보드
    최종 점수를 보여주고 상위 5명의 랭킹을 표시합니다.
    """
    def __init__(self, screen, clock):
        super().__init__(screen, clock)
        self.time = 0.0
        self.sw = screen.get_width()
        self.sh = screen.get_height()
        
        self.particles = [Particle(self.sw, self.sh) for _ in range(PARTICLE_COUNT)]
        self.leaderboard_data = []
        
        self._init_fonts()
        self._init_cached_surfaces()

    def reset(self):
        """화면 진입 시마다 호출됨"""
        self.time = 0.0
        self.score = config.LAST_SCORE
        self.max_combo = config.LAST_COMBO
        self.leaderboard_data = leaderboard.load_leaderboard()[:5]

    def _init_fonts(self):
        korean_fonts = ["malgun gothic", "malgungothic", "gulim", "dotum"]
        font_name = None
        for fname in korean_fonts:
            if fname in [f.lower() for f in pygame.font.get_fonts()]:
                font_name = fname
                break
                
        scale = self.sh / 600.0
        if font_name:
            self.font_title = pygame.font.SysFont(font_name, int(48 * scale), bold=True)
            self.font_score = pygame.font.SysFont(font_name, int(64 * scale), bold=True)
            self.font_combo = pygame.font.SysFont(font_name, int(24 * scale), bold=True)
            self.font_rank = pygame.font.SysFont(font_name, int(20 * scale), bold=True)
            self.font_hint = pygame.font.SysFont(font_name, int(16 * scale))
        else:
            self.font_title = pygame.font.Font(None, int(60 * scale))
            self.font_score = pygame.font.Font(None, int(80 * scale))
            self.font_combo = pygame.font.Font(None, int(30 * scale))
            self.font_rank = pygame.font.Font(None, int(26 * scale))
            self.font_hint = pygame.font.Font(None, int(20 * scale))

    def _init_cached_surfaces(self):
        self._bg_surface = pygame.Surface((self.sw, self.sh))
        for y in range(0, self.sh, 2):
            ratio = y / self.sh
            r = int(COLOR_BG_DARK[0] * (1 - ratio) + (20, 0, 40)[0] * ratio)
            g = int(COLOR_BG_DARK[1] * (1 - ratio) + (20, 0, 40)[1] * ratio)
            b = int(COLOR_BG_DARK[2] * (1 - ratio) + (20, 0, 40)[2] * ratio)
            pygame.draw.rect(self._bg_surface, (r, g, b), (0, y, self.sw, 2))

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RETURN or event.key == pygame.K_SPACE or event.key == pygame.K_ESCAPE:
                self.next_screen = "start"
            elif event.key == pygame.K_r:
                leaderboard.reset_leaderboard()
                self.leaderboard_data = []
        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                self.next_screen = "start"

    def handle_trigger(self, event):
        """
        파이썬 UI는 이제 FPGA state를 보고 화면을 전환하므로 버튼 신호에 의한 화면 전환은 무시합니다.
        """
        pass

    def update(self, dt):
        self.time += dt
        for particle in self.particles:
            particle.update(dt, self.time)

    def draw(self):
        self.screen.blit(self._bg_surface, (0, 0))
        for particle in self.particles:
            particle.draw(self.screen)
            
        cx = self.sw // 2
        
        # 1. 상단: 내 점수 결과
        pulse = 0.5 + 0.5 * math.sin(self.time * 3.0)
        title_color = (int(COLOR_NEON_CYAN[0] * pulse), int(COLOR_NEON_CYAN[1] * pulse), int(COLOR_NEON_CYAN[2] * pulse))
        
        title_surf = self.font_title.render("STAGE CLEAR!", True, title_color)
        self.screen.blit(title_surf, title_surf.get_rect(center=(cx, int(self.sh * 0.15))))
        
        score_surf = self.font_score.render(f"{self.score:07d}", True, COLOR_WHITE)
        self.screen.blit(score_surf, score_surf.get_rect(center=(cx, int(self.sh * 0.28))))
        

        
        # 구분선
        pygame.draw.line(self.screen, COLOR_NEON_PURPLE, (int(self.sw * 0.1), int(self.sh * 0.45)), (int(self.sw * 0.9), int(self.sh * 0.45)), 2)
        
        # 2. 하단: 리더보드 (명예의 전당)
        lb_title = self.font_title.render("HALL OF FAME", True, COLOR_NEON_CYAN)
        self.screen.blit(lb_title, lb_title.get_rect(center=(cx, int(self.sh * 0.52))))
        
        start_y = int(self.sh * 0.60)
        item_h = int(self.sh * 0.06)
        
        for i, entry in enumerate(self.leaderboard_data):
            y = start_y + i * item_h
            
            # 등수 별 색상 처리
            if i == 0: color = (255, 215, 0) # Gold
            elif i == 1: color = (192, 192, 192) # Silver
            elif i == 2: color = (205, 127, 50) # Bronze
            else: color = COLOR_GRAY
            
            rank_text = f"#{i+1}"
            rank_text = f"#{i+1}"
            score_text = f"{entry.get('score', 0):07d}"
            
            # 텍스트 렌더링
            r_surf = self.font_rank.render(rank_text, True, color)
            s_surf = self.font_rank.render(score_text, True, COLOR_NEON_CYAN)
            
            self.screen.blit(r_surf, (cx - 100, y - r_surf.get_height()//2))
            self.screen.blit(s_surf, (cx + 20, y - s_surf.get_height()//2))

        # 3. 하단 안내 문구
        hint_surf = self.font_hint.render("PRESS START TO CONTINUE", True, COLOR_TEXT_DIM)
        self.screen.blit(hint_surf, hint_surf.get_rect(center=(cx, self.sh - 30)))

        # 4. 리셋 안내 문구 (우측 하단)
        reset_text = self.font_hint.render("PRESS [R] TO RESET BOARD", True, (150, 80, 100))
        self.screen.blit(reset_text, reset_text.get_rect(center=(self.sw - 120, self.sh - 30)))
