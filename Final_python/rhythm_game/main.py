# -*- coding: utf-8 -*-
"""
리듬게임 UI - 메인 진입점 (main.py)

FPGA UART 통신 기반 리듬게임의 진입점입니다.
pygame 윈도우를 초기화하고, 화면(Screen) 객체들을 관리하며,
메인 게임 루프를 실행합니다.

실행 방법:
  python main.py

조작법 (키보드 폴백 모드):
  - Enter/Space : 시작 화면 -> 곡 선택 화면
  - 좌/우 방향키 : 곡 목록 이동
  - Space/Enter : 곡 확정 (게임 시작)
  - A, S, D, F  : 게임 플레이 (레인 0~3 입력)
  - Esc          : 이전 화면 / 종료

FPGA 연결 시:
  - UART를 통해 FPGA 보드의 버튼 입력이 위 키보드 입력을 대체합니다.
  - config.py의 트리거 코드 참조.
"""

import sys
import pygame

import config
from uart_handler import UARTHandler
from screens.start_screen import StartScreen
from screens.select_screen import SelectScreen
from screens.game_screen import GameScreen
from screens.result_screen import ResultScreen


# ============================================================
# RhythmGame 메인 클래스
# ============================================================
class RhythmGame:
    """
    리듬게임 메인 애플리케이션

    전체 게임의 생명주기를 관리합니다:
      1. 초기화: pygame, 화면, UART 설정
      2. 메인 루프: 이벤트 처리 -> UART 수신 -> 상태 업데이트 -> 렌더링
      3. 종료: UART 해제, pygame 정리
    """

    def __init__(self):
        """게임 초기화 - pygame, 디스플레이, UART, 화면 인스턴스 생성"""

        # ---- pygame 초기화 ----
        pygame.mixer.pre_init(44100, -16, 2, 512)
        pygame.init()
        pygame.display.set_caption("RHYTHM BEAT - FPGA Rhythm Game")

        # ---- 디스플레이 설정 ----
        if config.FULLSCREEN:
            # 전체화면 모드: 모니터 해상도를 자동 감지하여 적용
            display_info = pygame.display.Info()
            screen_w = display_info.current_w
            screen_h = display_info.current_h
            self.screen = pygame.display.set_mode(
                (screen_w, screen_h),
                pygame.FULLSCREEN,
            )
            # config의 해상도를 실제 모니터 값으로 갱신
            config.SCREEN_WIDTH = screen_w
            config.SCREEN_HEIGHT = screen_h
        else:
            # 창 모드: config에 지정된 해상도 사용
            self.screen = pygame.display.set_mode(
                (config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
            )

        # 전체화면 시 마우스 커서 숨기기
        if config.FULLSCREEN:
            pygame.mouse.set_visible(False)

        self.clock = pygame.time.Clock()
        self.running = True

        # ---- UART 통신 초기화 ----
        # FPGA 보드와의 시리얼 통신을 시작합니다.
        # 연결 실패 시 자동으로 키보드 폴백 모드로 전환됩니다.
        self.uart = UARTHandler()
        self.uart.start()

        # ---- 화면(Screen) 인스턴스 생성 ----
        # 각 화면은 독립적인 상태와 렌더링 로직을 가집니다.
        # 화면 간 전환은 next_screen 속성으로 관리됩니다.
        self.screens = {
            "start":  StartScreen(self.screen, self.clock),
            "select": SelectScreen(self.screen, self.clock),
            "game":   GameScreen(self.screen, self.clock),
            "result": ResultScreen(self.screen, self.clock),
        }
        for screen in self.screens.values():
            screen.send_tx = self.uart.send_to_fpga
            
        self.current_screen_name = "start"
        
        self.last_raw_packet = None
        font_name = "consolas" if "consolas" in pygame.font.get_fonts() else None
        self.debug_font = pygame.font.SysFont(font_name, 16, bold=True)

    # --------------------------------------------------------
    # 속성 (Property)
    # --------------------------------------------------------
    @property
    def current_screen(self):
        """현재 활성화된 화면 객체를 반환합니다."""
        return self.screens[self.current_screen_name]

    # --------------------------------------------------------
    # 화면 전환
    # --------------------------------------------------------
    def _switch_screen(self, screen_name):
        """
        지정된 이름의 화면으로 전환합니다.

        게임 화면으로 진입할 때는 자동으로 reset()을 호출하여
        점수, 콤보, 노트 등의 상태를 초기화합니다.

        Args:
            screen_name: 전환할 화면 이름 ("start", "select", "game")
        """
        if screen_name in self.screens:
            print(f"[GAME] 화면 전환: {self.current_screen_name} -> {screen_name}")

            # 게임 화면을 벗어날 때 무조건 노래 끄기
            if self.current_screen_name == "game" and screen_name != "game":
                pygame.mixer.music.stop()

            # 게임 -> 결과창으로 넘어갈 때 무조건 점수 저장
            if self.current_screen_name == "game" and screen_name == "result":
                import leaderboard
                config.LAST_SCORE = self.current_screen.score
                config.LAST_COMBO = self.current_screen.max_combo
                leaderboard.save_score("PLAYER", config.LAST_SCORE, config.LAST_COMBO)

            self.current_screen_name = screen_name

            # 화면 진입 시 상태 초기화 (곡 데이터 재로드 포함)
            if hasattr(self.current_screen, "reset"):
                self.current_screen.reset()

    # --------------------------------------------------------
    # 메인 게임 루프
    # --------------------------------------------------------
    def run(self):
        """
        메인 게임 루프를 실행합니다.

        매 프레임마다 다음 순서로 처리합니다:
          1. pygame 이벤트 (키보드, 마우스, 종료 등)
          2. UART 트리거 수신 (FPGA -> PC)
          3. 현재 화면 상태 업데이트
          4. 화면 전환 체크
          5. 렌더링 및 화면 갱신
        """
        # ---- 시작 배너 출력 ----
        print("=" * 50)
        print("  RHYTHM BEAT - FPGA 리듬게임 UI")
        print("=" * 50)
        if self.uart.is_connected():
            print("  [UART] FPGA 연결됨")
        else:
            print("  [UART] 키보드 폴백 모드")
        print("  [KEY]  Enter=시작, 좌우=이동, Space=선택, Esc=종료")
        print(f"  [SCREEN] {self.screen.get_width()}x{self.screen.get_height()}"
              f" {'(전체화면)' if config.FULLSCREEN else '(창모드)'}")
        print("=" * 50)

        # ---- 프레임 루프 ----
        while self.running:
            # dt: 이전 프레임과의 시간 차이 (초 단위)
            # FPS를 유지하면서 프레임 독립적인 업데이트를 가능하게 합니다.
            dt = self.clock.tick(config.FPS) / 1000.0

            # -- 1단계: pygame 이벤트 처리 --
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    # 창 닫기 버튼
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_F11:
                        config.FULLSCREEN = not config.FULLSCREEN
                        pygame.display.toggle_fullscreen()
                        pygame.mouse.set_visible(not config.FULLSCREEN)
                    # 시작 화면에서 ESC -> 프로그램 종료
                    elif event.key == pygame.K_ESCAPE and self.current_screen_name == "start":
                        self.running = False
                    else:
                        # 현재 화면에 이벤트 전달
                        self.current_screen.handle_event(event)
                else:
                    # 키업, 마우스 클릭 등 기타 이벤트
                    self.current_screen.handle_event(event)

            # -- 2단계: UART 트리거 처리 (FPGA -> PC) --
            # 큐에 쌓인 모든 트리거를 이번 프레임에 처리합니다.
            trigger = self.uart.get_event()
            while trigger is not None:
                # 딕셔너리로 바뀐 7바이트 이벤트 정보를 화면에 출력 (렉 방지를 위해 주석 처리)
                # print(f"[UART] 이벤트 수신: {trigger}")
                if "raw_packet" in trigger:
                    self.last_raw_packet = trigger["raw_packet"]
                    
                # FPGA State 기반 전역 화면 전환
                if "state" in trigger:
                    fpga_state = trigger["state"]
                    target_screen = None
                    if fpga_state == config.IDLE:
                        target_screen = "start"
                    elif fpga_state == config.SELECT:
                        target_screen = "select"
                    elif fpga_state in (config.READY, config.GAME_CONT):
                        target_screen = "game"
                    elif fpga_state in (config.CAPTURE, config.DONE):
                        target_screen = "result"

                    if target_screen and self.current_screen_name != target_screen:
                        self._switch_screen(target_screen)

                self.current_screen.handle_trigger(trigger)
                trigger = self.uart.get_event()

            # -- 3단계: 현재 화면 상태 업데이트 --
            self.current_screen.update(dt)

            # -- 4단계: 화면 전환 체크 --
            # 현재 화면이 next_screen을 설정했으면 해당 화면으로 전환
            next_screen = self.current_screen.get_next_screen()
            if next_screen:
                self._switch_screen(next_screen)

            # -- 5단계: 렌더링 --
            self.current_screen.draw()
            
            # 우측 상단에 UART 디버그 로그 오버레이 그리기
            if self.last_raw_packet or self.uart.last_tx_byte is not None:
                texts = []
                if self.last_raw_packet:
                    raw_bin_str = " ".join([f"{b:08b}" for b in self.last_raw_packet])
                    legend_str  = "HEADER   -SSSUDRL ---HFPGM CCCCCCCC SSSSSSSS SSSSSSSS SSSSSSSS"
                    texts.append((f"       [{legend_str}]", (255, 200, 0)))
                    texts.append((f"RX: [{raw_bin_str}]", (0, 255, 100)))
                    
                if self.uart.last_tx_byte is not None:
                    tx_b = self.uart.last_tx_byte
                    tx_bin_str = f"{tx_b:08b}"
                    texts.append((f"TX: [{tx_bin_str}] (Lane Mask)", (255, 100, 200)))
                    
                surfaces = [self.debug_font.render(t, True, c) for t, c in texts]
                bg_width = max([s.get_width() for s in surfaces]) + 10
                bg_height = sum([s.get_height() for s in surfaces]) + 5 * (len(surfaces) + 1)
                
                bg_rect = pygame.Rect(self.screen.get_width() - bg_width - 10, 10, bg_width, bg_height)
                
                # 가독성을 위한 반투명 검은색 배경 
                bg_surface = pygame.Surface((bg_width, bg_height), pygame.SRCALPHA)
                bg_surface.fill((0, 0, 0, 180))
                
                self.screen.blit(bg_surface, (bg_rect.x, bg_rect.y))
                
                cy = bg_rect.y + 5
                for s in surfaces:
                    self.screen.blit(s, (bg_rect.x + 5, cy))
                    cy += s.get_height() + 5

            pygame.display.flip()

        # ---- 종료 처리 ----
        self.uart.stop()
        pygame.quit()
        print("[GAME] 프로그램 종료")


# ============================================================
# 프로그램 진입점
# ============================================================
if __name__ == "__main__":
    game = RhythmGame()
    game.run()
