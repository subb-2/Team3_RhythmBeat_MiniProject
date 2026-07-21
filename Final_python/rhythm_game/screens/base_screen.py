# -*- coding: utf-8 -*-
"""
화면 베이스 클래스 (base_screen.py)

모든 화면(Screen)이 상속받는 추상 클래스입니다.
각 화면은 이 클래스를 상속하여 다음 4개의 메서드를 구현해야 합니다:
  - handle_event():   pygame 이벤트(키보드, 마우스 등) 처리
  - handle_trigger(): FPGA UART 트리거 신호 처리
  - update():         프레임별 상태 업데이트
  - draw():           화면 렌더링

화면 전환은 next_screen 속성을 설정하면,
메인 루프(main.py)에서 get_next_screen()으로 감지하여 전환합니다.
"""

from abc import ABC, abstractmethod


class BaseScreen(ABC):
    """
    화면 베이스 클래스 (추상 클래스)

    모든 화면의 공통 인터페이스를 정의합니다.
    하위 클래스: StartScreen, SelectScreen, GameScreen
    """

    def __init__(self, screen, clock):
        """
        Args:
            screen: pygame.Surface - 렌더링 대상 서피스
            clock:  pygame.time.Clock - 프레임 레이트 관리용 클럭
        """
        self.screen = screen
        self.clock = clock
        self.next_screen = None     # 전환할 다음 화면 이름 (None이면 현재 화면 유지)
        self.send_tx = None         # UART TX 전송 콜백 함수

    @abstractmethod
    def handle_event(self, event):
        """pygame 이벤트 처리 (키보드, 마우스 등)"""
        pass

    @abstractmethod
    def handle_trigger(self, trigger):
        """FPGA UART 트리거 신호 처리"""
        pass

    @abstractmethod
    def update(self, dt):
        """
        화면 상태 업데이트

        Args:
            dt: 이전 프레임과의 시간 차이 (초 단위, 프레임 독립적 업데이트용)
        """
        pass

    @abstractmethod
    def draw(self):
        """화면 렌더링 - 현재 상태를 screen 서피스에 그립니다"""
        pass

    def get_next_screen(self):
        """
        전환할 다음 화면 이름을 반환합니다.

        메인 루프에서 매 프레임 호출하여 화면 전환 여부를 확인합니다.
        한번 읽으면 자동으로 None으로 리셋됩니다 (일회성 전환 신호).

        Returns:
            str 또는 None: 전환할 화면 이름 ("start", "select", "game"), 없으면 None
        """
        result = self.next_screen
        self.next_screen = None
        return result
