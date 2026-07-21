# -*- coding: utf-8 -*-
"""
곡 선택 화면 (Select Screen) 모듈

게임 시작 후 플레이어가 플레이할 곡을 고르는 화면입니다.
좌우 화살표를 통해 앨범 아트를 캐러셀 형태로 회전시키며 곡을 탐색할 수 있고,
선택된 곡 정보는 config 모듈에 저장되어 게임 화면 진입 시 참조됩니다.

주요 구성 요소:
- SelectScreen: 캐러셀 애니메이션, 곡 메타데이터 렌더링, 이벤트 처리 등 총괄
- 원형 앨범 아트 마스킹: 네모난 앨범 이미지를 부드러운 원형으로 깎아 캐러셀로 표현
- 백그라운드 파티클 및 그리드 스크롤 투시 배경 장식
"""

import pygame
import math
import random
import os

from screens.base_screen import BaseScreen
# 파일 내부가 아닌 상단에서 전체 참조 모듈 임포트
import config
from config import (
    COLOR_WHITE, COLOR_GRAY,
    SONG_LIST,
)

# ============================================================
# 색상 상수 (레트로 아케이드 팔레트)
# ============================================================
C_BG_DARK = (8, 4, 28)           # 바탕의 가장 깊은 남색 
C_BG_PURPLE = (20, 8, 48)        # 그라데이션용 보라빛 색조
C_NEON_CYAN = (0, 255, 245)      # 주요 강조 선이나 타이틀 테두리 등에 쓰는 밝은 시안
C_NEON_PINK = (255, 0, 150)      # 장식용 핑크 네온 
C_NEON_PURPLE = (180, 80, 255)   # 비활성화된 아이템 등에 씌우는 퍼플 톤
C_NEON_YELLOW = (255, 220, 50)   # 별점 등 난이도 강조를 위한 노란색 네온
C_GRID_LINE = (30, 15, 70)       # 화면 바닥을 가로지르는 원근감 그리드 선
C_TEXT_DIM = (140, 130, 180)     # 메인 정보가 아닌 서브 텍스트용 어두운 계열


# ============================================================
# 메인 클래스
# ============================================================
class SelectScreen(BaseScreen):
    """
    곡 선택 화면 클래스
    
    사용자 조작을 통해 곡 리스트(SONG_LIST)를 좌우로 순환하면서 탐색하고,
    결정한 후 게임 화면으로 진입할 수 있도록 돕습니다.
    """

    # --------------------------------------------------------
    # 초기화
    # --------------------------------------------------------
    def __init__(self, screen, clock):
        """
        초기화 과정을 통해 시각적 요소(폰트, 표면, 캐러셀 이미지)를 준비합니다.
        """
        super().__init__(screen, clock)
        self.time = 0.0
        
        # 현재 화면 중앙에 위치하여 선택 중인 곡의 리스트 인덱스 번호
        self.selected_index = 0
        self.songs = SONG_LIST

        # 해상도 확인
        self.sw = screen.get_width()
        self.sh = screen.get_height()

        # 캐러셀에서 중앙 아이템과 가장자리 아이템의 앨범 아트 크기를 다르게 책정
        self.album_size_big = int(min(self.sw, self.sh) * 0.42)
        self.album_size_small = int(self.album_size_big * 0.55)

        # 좌우 이동 애니메이션 시 부드러운 전환을 위한 보간값 변수들
        self.anim_offset = 0.0
        self.anim_target = 0.0
        self.anim_speed = 10.0

        # 최종 선택이 완료되어 게임 뷰로 넘어가는 순간 화면을 하얗게/파랗게 물들이는 효과량
        self.select_flash = 0.0

        # 곡들에 배정된 앨범 이미지를 딕셔너리로 보유
        self.album_images = {}
        self._load_album_images()

        # 화면 뒤에서 위로 천천히 떠오르는 별자리 느낌 파티클 데이터 배열
        self.stars = []
        for _ in range(50):
            self.stars.append({
                "x": random.randint(0, self.sw),
                "y": random.randint(0, self.sh),
                "size": random.randint(1, 2),
                "speed": random.uniform(0.3, 1.5),
                "alpha": random.randint(80, 200),
                "pulse_speed": random.uniform(1.0, 4.0),
                "pulse_offset": random.uniform(0, math.pi * 2),
            })

        # 레트로 바닥망 이동 애니메이션을 위한 오프셋 기록값
        self.grid_scroll = 0.0

        # 시각 요소 렌더링 리소스 로드
        self._init_fonts()
        self._init_cached_surfaces()

    # --------------------------------------------------------
    # 캐싱 및 리소스 준비
    # --------------------------------------------------------
    def _init_cached_surfaces(self):
        """
        변경되지 않는 배경 그라데이션 및 스캔라인 오버레이 등을
        Surface 객체로 단 한 번 렌더링하여 메모리에 저장합니다.
        """
        # 1. 상단에서 하단으로 이어지는 보라 계열 그라데이션 캐싱
        self._bg_surface = pygame.Surface((self.sw, self.sh))
        for y in range(0, self.sh, 2):
            ratio = y / self.sh
            r = int(C_BG_DARK[0] * (1 - ratio) + C_BG_PURPLE[0] * ratio)
            g = int(C_BG_DARK[1] * (1 - ratio) + C_BG_PURPLE[1] * ratio)
            b = int(C_BG_DARK[2] * (1 - ratio) + C_BG_PURPLE[2] * ratio)
            pygame.draw.rect(self._bg_surface, (r, g, b), (0, y, self.sw, 2))

        # 2. 브라운관 TV 느낌 연출용 가로 스캔라인 투명 마스크 레이어
        self._scanline_surface = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
        for y in range(0, self.sh, 3):
            pygame.draw.line(self._scanline_surface, (0, 0, 0, 20), (0, y), (self.sw, y), 1)

        # 3. 임시로 그림을 덧대어 그릴 때 사용할 재활용 투명 캔버스
        self._overlay = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)

    def _init_fonts(self):
        """
        UI 화면에 띄울 각종 한글 텍스트용 폰트들을 불러와 준비시킵니다.
        """
        korean_fonts = ["malgun gothic", "malgungothic", "gulim", "dotum"]
        font_name = None
        for fname in korean_fonts:
            if fname in [f.lower() for f in pygame.font.get_fonts()]:
                font_name = fname
                break

        # 창 크기 비례에 맞춘 폰트 스케일값 지정
        scale = self.sh / 600.0
        
        if font_name:
            self.font_header = pygame.font.SysFont(font_name, int(20 * scale), bold=True)
            self.font_tab = pygame.font.SysFont(font_name, int(22 * scale), bold=True)
            self.font_title = pygame.font.SysFont(font_name, int(38 * scale), bold=True)
            self.font_artist = pygame.font.SysFont(font_name, int(20 * scale))
            self.font_icon = pygame.font.SysFont(font_name, int(16 * scale), bold=True)
            self.font_diff = pygame.font.SysFont(font_name, int(18 * scale), bold=True)
            self.font_hint = pygame.font.SysFont(font_name, int(14 * scale))
        else:
            self.font_header = pygame.font.Font(None, int(28 * scale))
            self.font_tab = pygame.font.Font(None, int(30 * scale))
            self.font_title = pygame.font.Font(None, int(50 * scale))
            self.font_artist = pygame.font.Font(None, int(28 * scale))
            self.font_icon = pygame.font.Font(None, int(22 * scale))
            self.font_diff = pygame.font.Font(None, int(24 * scale))
            self.font_hint = pygame.font.Font(None, int(18 * scale))

    def _load_album_images(self):
        """
        곡 설정 데이터에 적힌 앨범 아트 원본 이미지를 불러옵니다.
        불러온 이미지는 곧장 원형으로 마스킹 커팅된 캐러셀용 크기 둘로 쪼개어 캐싱합니다.
        """
        for i, song in enumerate(self.songs):
            img_path = song.get("image", "")
            if os.path.exists(img_path):
                try:
                    raw = pygame.image.load(img_path).convert_alpha()
                    # 정중앙과 외곽 둘을 위해 크기별로 원형 가공 함수 호출
                    self.album_images[i] = {
                        "big": self._make_circular_fast(raw, self.album_size_big),
                        "small": self._make_circular_fast(raw, self.album_size_small),
                    }
                except Exception as e:
                    print(f"[SELECT] 이미지 로드 실패: {img_path} - {e}")
                    self.album_images[i] = None
            else:
                print(f"[SELECT] 이미지 없음: {img_path}")
                self.album_images[i] = None

    def _make_circular_fast(self, surface, size):
        """
        사각형 이미지를 받아 정중앙을 기준으로 원형으로 도려낸 후
        원하는 해상도 크기로 부드럽게 리사이징하여 반환합니다.
        
        Args:
            surface (pygame.Surface): 가공할 대상 원본 이미지
            size (int): 가공 후 반환할 최종 정사각형 너비/높이
            
        Returns:
            pygame.Surface: 배경 투명 알파 채널이 적용된 둥근 테두리의 이미지 객체
        """
        src_w, src_h = surface.get_size()
        min_dim = min(src_w, src_h)
        crop_x = (src_w - min_dim) // 2
        crop_y = (src_h - min_dim) // 2
        cropped = surface.subsurface((crop_x, crop_y, min_dim, min_dim))
        scaled = pygame.transform.smoothscale(cropped, (size, size))

        result = pygame.Surface((size, size), pygame.SRCALPHA)
        # 하얀 원을 먼저 그림
        pygame.draw.circle(result, (255, 255, 255, 255), (size // 2, size // 2), size // 2)
        # 그 위에 축소된 이미지를 '투명도 최소값 합성 방식'으로 덧씌우면 원 영역만 이미지가 남음
        result.blit(scaled, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)
        return result

    # --------------------------------------------------------
    # 렌더링
    # --------------------------------------------------------
    def _draw_bg(self):
        """
        캐싱된 뒷배경 그라데이션 층을 깔고 그 위에 네온스타일 바닥 선반(원근감)과
        올라오는 장식용 별가루 파티클을 오버레이 처리합니다.
        """
        self.screen.blit(self._bg_surface, (0, 0))

        # 투시 그리드 바닥 선을 전용 오버레이 서피스에 일시적으로 그려 병합
        self._overlay.fill((0, 0, 0, 0))
        cx, cy = self.sw // 2, self.sh

        # 가로 다가오는 선형 스크롤
        for i in range(10):
            progress = (i / 10 + self.grid_scroll) % 1.0
            y = int(cy - (progress ** 1.5) * self.sh * 0.8)
            alpha = int(35 * (1 - progress))
            if alpha > 3:
                half_w = int(self.sw * 0.4 * (1 - progress * 0.7))
                pygame.draw.line(self._overlay, (*C_GRID_LINE[:3], alpha),
                               (cx - half_w, y), (cx + half_w, y), 1)

        # 세로 퍼져나가는 방사 선들
        for angle_offset in range(-4, 5):
            x_end = cx + int(angle_offset * self.sw * 0.1)
            pygame.draw.line(self._overlay, (*C_GRID_LINE[:3], 18),
                           (cx, int(self.sh * 0.2)), (x_end, self.sh), 1)

        self.screen.blit(self._overlay, (0, 0))

        # 공중에 흩날리는 점박이 배경 별
        for star in self.stars:
            pulse = 0.5 + 0.5 * math.sin(self.time * star["pulse_speed"] + star["pulse_offset"])
            if pulse > 0.3:
                pygame.draw.circle(self.screen, (220, 230, 255),
                                 (star["x"], star["y"]), star["size"])

    def _draw_top_ui(self):
        """
        화면 최상단에 놓여 장식미를 더하는 가로 배너 형태 UI 레이어를 그립니다.
        """
        cx = self.sw // 2
        banner_h = int(self.sh * 0.12)

        # 배너 베이스 판
        pygame.draw.rect(self.screen, (5, 2, 15), (0, 0, self.sw, banner_h))
        # 배너 밑줄
        pygame.draw.line(self.screen, C_NEON_CYAN, (0, banner_h - 2), (self.sw, banner_h - 2), 2)

        title_text = self.font_header.render("  SELECT  ", True, C_NEON_CYAN)
        self.screen.blit(title_text, title_text.get_rect(center=(cx, banner_h // 2)))

        # 장식용 다이아몬드 도형 양 끝 배치
        dia_y = banner_h // 2
        for dx in [-int(self.sw * 0.35), int(self.sw * 0.35)]:
            dia_x = cx + dx
            size = 6
            pts = [(dia_x, dia_y - size), (dia_x + size, dia_y),
                   (dia_x, dia_y + size), (dia_x - size, dia_y)]
            pygame.draw.polygon(self.screen, C_NEON_PINK, pts)

    def _draw_bottom_ui(self):
        """
        화면 하단의 현재 선택된 곡 관련 상세 텍스트(곡명, 난이도 등)와 조작법 힌트를 띄웁니다.
        """
        cx = self.sw // 2
        song = self.songs[self.selected_index]

        panel_h = int(self.sh * 0.28)
        panel_y = self.sh - panel_h

        # 정보 패널 뒷배경 판
        pygame.draw.rect(self.screen, (5, 2, 18), (0, panel_y, self.sw, panel_h))
        # 윗 선
        pygame.draw.line(self.screen, C_NEON_PINK, (0, panel_y), (self.sw, panel_y), 2)

        # 중앙 곡 타이틀 글자
        title_y = panel_y + int(panel_h * 0.25)
        title_surf = self.font_title.render(song["title"], True, COLOR_WHITE)
        self.screen.blit(title_surf, title_surf.get_rect(center=(cx, title_y)))

        # 곡 난이도(별표 개수) 
        diff_y = title_y + int(panel_h * 0.25)
        diff = song.get("difficulty", "☆☆☆☆☆")
        diff_surf = self.font_diff.render(f"난이도  {diff}", True, C_NEON_YELLOW)
        self.screen.blit(diff_surf, diff_surf.get_rect(center=(cx, diff_y)))

        # 전체 인덱스 수식 ( - 1 / 2 - ) 등
        num_y = diff_y + int(panel_h * 0.2)
        num_text = f"- {self.selected_index + 1} / {len(self.songs)} -"
        num_surf = self.font_icon.render(num_text, True, C_TEXT_DIM)
        self.screen.blit(num_surf, num_surf.get_rect(center=(cx, num_y)))

        # 바닥 사용자 조작 매뉴얼 텍스트 (알파값 펄스 처리)
        hint_y = self.sh - int(self.sh * 0.03)
        pulse = 0.6 + 0.4 * math.sin(self.time * 3.0)
        hint_color = (int(C_NEON_CYAN[0] * pulse), int(C_NEON_CYAN[1] * pulse), int(C_NEON_CYAN[2] * pulse))
        hint_text = " 좌 우 : 곡 선택  |  SPACE / ENTER : 게임 시작  |  ESC : 뒤로 가기 "
        hint_surf = self.font_hint.render(hint_text, True, hint_color)
        self.screen.blit(hint_surf, hint_surf.get_rect(center=(cx, hint_y)))

    def _draw_album_circle(self, song_index, cx, cy, size, is_selected, alpha=255):
        """
        저장된 캐싱 이미지 풀에서 앨범아트를 찾아내 지정한 픽셀 지점에 배치합니다.
        가장자리의 아트웍일 경우 alpha를 적용하여 투명도를 주고 어둡게 덮습니다.
        """
        real_index = song_index % len(self.songs)
        img_data = self.album_images.get(real_index)
        
        if img_data:
            base_key = "big" if size > self.album_size_small + 10 else "small"
            base_img = img_data[base_key]

            # 보간 애니메이션 과정에서 크기가 다를 땐 즉석 스무딩 리사이즈
            if base_img.get_width() != size:
                img = pygame.transform.smoothscale(base_img, (size, size))
            else:
                img = base_img

            img_rect = img.get_rect(center=(cx, cy))

            # 포커싱 되지 않은 앨범인 경우 어두운 필터를 씌움
            if alpha < 255:
                dark_img = img.copy()
                dark_overlay = pygame.Surface((size, size), pygame.SRCALPHA)
                dark_overlay.fill((0, 0, 0, int(255 - alpha * 0.6)))
                dark_img.blit(dark_overlay, (0, 0))
                dark_img.set_alpha(alpha)
                self.screen.blit(dark_img, img_rect)
            else:
                self.screen.blit(img, img_rect)
        else:
            # 불러올 원본 이미지가 누락된 경우 기본 음표 원형 마크 생성
            pygame.draw.circle(self.screen, (40, 20, 80), (cx, cy), size // 2)
            pygame.draw.circle(self.screen, C_NEON_PURPLE, (cx, cy), size // 2, 2)
            note_text = self.font_title.render("음", True, C_NEON_PURPLE)
            self.screen.blit(note_text, note_text.get_rect(center=(cx, cy)))

    def _draw_carousel(self):
        """
        좌, 중, 우 순서로 화면 내 앨범 아트 캐러셀 구도를 계산하여 렌더링하고
        각각의 아이템을 스크롤 속도에 맞추어 확대/축소 및 위치 이동시킵니다.
        """
        cx = self.sw // 2
        cy = int(self.sh * 0.43)
        spacing = int(self.sw * 0.36)
        offset = self.anim_offset
        num_songs = len(self.songs)

        # 화면 양 끝 화살표 모양 렌더
        arrow_y = cy
        arrow_pulse = 0.6 + 0.4 * math.sin(self.time * 4.0)
        arrow_color = (int(C_NEON_CYAN[0] * arrow_pulse),
                      int(C_NEON_CYAN[1] * arrow_pulse),
                      int(C_NEON_CYAN[2] * arrow_pulse))

        # 좌측 화살표
        la_x = int(self.sw * 0.04)
        pygame.draw.polygon(self.screen, arrow_color,
                          [(la_x + 25, arrow_y - 20), (la_x + 25, arrow_y + 20), (la_x, arrow_y)])
        pygame.draw.polygon(self.screen, C_NEON_CYAN,
                          [(la_x + 25, arrow_y - 20), (la_x + 25, arrow_y + 20), (la_x, arrow_y)], 2)

        # 우측 화살표
        ra_x = self.sw - int(self.sw * 0.04)
        pygame.draw.polygon(self.screen, arrow_color,
                          [(ra_x - 25, arrow_y - 20), (ra_x - 25, arrow_y + 20), (ra_x, arrow_y)])
        pygame.draw.polygon(self.screen, C_NEON_CYAN,
                          [(ra_x - 25, arrow_y - 20), (ra_x - 25, arrow_y + 20), (ra_x, arrow_y)], 2)

        # 그리기 우선순위를 위해 뒷편(양 사이드) 아이템부터 그리고 중심 아이템을 맨 마지막에 그림
        positions = [pos for pos in range(-2, 3)]
        positions.sort(key=lambda x: abs(x + offset), reverse=True)

        for rel_pos in positions:
            idx = (self.selected_index + rel_pos) % num_songs
            x = cx + (rel_pos + offset) * spacing
            y = cy

            # 화면 밖으로 벗어나는 영역 렌더링 무시
            if x < -self.album_size_big or x > self.sw + self.album_size_big:
                continue

            dist = abs(rel_pos + offset)
            is_center = dist < 0.3

            if is_center:
                # 정중앙 선택된 항목
                pulse = 1.0 + 0.02 * math.sin(self.time * 3.0)
                size = int(self.album_size_big * pulse)
                border_r = size // 2 + 12

                # 후광 네온 효과 서클 연속으로 그리기
                glow_alpha_base = 0.7 + 0.3 * math.sin(self.time * 2.5)
                for gi in range(3, 0, -1):
                    pygame.draw.circle(self.screen, C_NEON_CYAN,
                                     (int(x), int(y)), border_r + gi * 3, 2)

                # 메인 앨범 테두리 원
                pygame.draw.circle(self.screen, (10, 5, 25), (int(x), int(y)), border_r)

                # 앨범 주위를 회전하는 두 핑크/시안색 장식 선분
                arc_rect = pygame.Rect(int(x) - border_r, int(y) - border_r,
                                      border_r * 2, border_r * 2)
                arc_start = self.time * 1.5
                pygame.draw.arc(self.screen, C_NEON_CYAN, arc_rect,
                              arc_start, arc_start + math.pi * 0.8, 3)
                pygame.draw.arc(self.screen, C_NEON_PINK, arc_rect,
                              arc_start + math.pi, arc_start + math.pi * 1.8, 3)

                self._draw_album_circle(idx, int(x), int(y), size, True, 255)

            else:
                # 주변 비선택 항목
                scale_factor = max(0.4, 1.0 - dist * 0.35)
                size = int(self.album_size_small * scale_factor)
                alpha = int(max(60, 255 - dist * 130))

                border_r = size // 2 + 8
                pygame.draw.circle(self.screen, (10, 5, 25), (int(x), int(y)), border_r)
                pygame.draw.circle(self.screen, C_NEON_PURPLE, (int(x), int(y)), border_r, 1)

                self._draw_album_circle(idx, int(x), int(y), size, False, alpha)

    def _draw_select_flash(self):
        """
        곡을 선택(게임 진입)했을 때 화면이 아주 짧은 순간 시안 빛으로
        밝게 번지며 전환되는 트랜지션 연출용 플래시를 오버레이합니다.
        """
        if self.select_flash > 0:
            flash_alpha = int(200 * self.select_flash)
            flash_surf = pygame.Surface((self.sw, self.sh), pygame.SRCALPHA)
            flash_surf.fill((*C_NEON_CYAN[:3], flash_alpha))
            self.screen.blit(flash_surf, (0, 0))

    # --------------------------------------------------------
    # 조작 및 데이터 변경
    # --------------------------------------------------------
    def _move_selection(self, direction):
        """
        실제로 커서를 이동시키고 캐러셀 애니메이션 출발 위치를 조정합니다.
        """
        self.selected_index = (self.selected_index + direction) % len(self.songs)
        config.SELECTED_SONG_INDEX = self.selected_index
        # 즉시 이동 후 화면은 부드럽게 따라오게 역으로 offset 밀기
        self.anim_offset = direction * 1.0
        self.anim_target = 0.0

    # --------------------------------------------------------
    # 이벤트 및 상태 업데이트
    # --------------------------------------------------------
    def handle_event(self, event):
        """
        마우스 및 키보드를 사용해 폴백 환경 등에서 곡 탐색/진입 작업을 수행합니다.
        """
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_LEFT or event.key == pygame.K_UP:
                self._move_selection(-1)
            elif event.key == pygame.K_RIGHT or event.key == pygame.K_DOWN:
                self._move_selection(1)
            elif event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_d):
                # 선택된 곡 번호를 config 전역 변수에 기록 후 뷰 전환
                config.SELECTED_SONG_INDEX = self.selected_index
                self.select_flash = 1.0
                self.next_screen = "game"
            elif event.key == pygame.K_ESCAPE:
                self.next_screen = "start"
                
        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:  # 왼쪽 버튼 클릭 시 즉시 스타트
                config.SELECTED_SONG_INDEX = self.selected_index
                self.select_flash = 1.0
                self.next_screen = "game"

    def handle_trigger(self, event):
        """
        UART 채널을 통해 날아오는 FPGA 이벤트 딕셔너리를 파싱하여
        캐러셀을 돌립니다. (화면 전환은 state 기반으로 main.py에서 처리됨)
        """
        if isinstance(event, dict):
            if event.get("left"):
                self._move_selection(-1)
            elif event.get("right"):
                self._move_selection(1)

    def update(self, dt):
        """
        프레임 사이의 유휴시간 단위 동안 애니메이션/스크롤 위치를 가산 갱신합니다.
        """
        self.time += dt

        # 부드러운 스크롤 복원
        if abs(self.anim_offset - self.anim_target) > 0.01:
            self.anim_offset += (self.anim_target - self.anim_offset) * self.anim_speed * dt
        else:
            self.anim_offset = self.anim_target

        # 별 부유
        for star in self.stars:
            star["y"] -= star["speed"] * dt * 30
            if star["y"] < -10:
                star["y"] = self.sh + 10
                star["x"] = random.randint(0, self.sw)

        # 그리드 이동
        self.grid_scroll = (self.grid_scroll + dt * 0.3) % 1.0

        # 선택 번쩍임 소멸 가속도
        if self.select_flash > 0:
            self.select_flash = max(0, self.select_flash - dt * 5.0)

    def draw(self):
        """
        구성된 화면 계층 순서대로 도화지 표면에 순서대로 찍어냅니다.
        배경 -> 상단 배너 -> 원형 캐러셀 메뉴 아트웍스 -> 곡 제목 및 힌트 하단 패널 -> CRT스캔라인 -> 플래시 트랜지션
        """
        self._draw_bg()
        self._draw_top_ui()
        self._draw_carousel()
        self._draw_bottom_ui()
        self.screen.blit(self._scanline_surface, (0, 0))
        self._draw_select_flash()
