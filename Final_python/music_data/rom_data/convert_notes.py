import os
import sys

# ============================================================
# [설정] 변환할 파일명 입력 (여기서 파일명을 수정하세요!)
# ============================================================
INPUT_FILENAME = "3.txt"           # 읽어들일 악보 텍스트 파일명
OUTPUT_FILENAME = "airplane2.mem"      # 생성될 롬 데이터 파일명
# ============================================================

# ============================================================
# [계이름 -> 레인 번호(16진수)] 매핑 규칙
# ============================================================
PITCH_MAP = {
    # 레인 1 (16진수: 8) - 저음
    "도": 8, "C": 8, "c": 8,
    "레": 8, "D": 8, "d": 8,
    
    # 레인 2 (16진수: 4) - 중저음
    "미": 4, "E": 4, "e": 4,
    "파": 4, "F": 4, "f": 4,
    
    # 레인 3 (16진수: 2) - 중고음
    "솔": 2, "G": 2, "g": 2,
    "라": 2, "A": 2, "a": 2,
    
    # 레인 4 (16진수: 1) - 고음
    "시": 1, "B": 1, "b": 1,
    "높은도": 1, "C5": 1, "c5": 1
}

def convert(input_file, output_file):
    if not os.path.exists(input_file):
        print(f"오류: '{input_file}' 파일을 찾을 수 없습니다.")
        return

    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    notes = []
    for line in lines:
        line = line.split('#')[0].strip() # 주석 무시
        if not line:
            continue
            
        parts = line.split()
        if len(parts) < 2:
            continue
            
        pitch = parts[0]
        try:
            beat = float(parts[1])
        except ValueError:
            print(f"경고: 박자 값이 숫자가 아닙니다 -> {line}")
            continue
            
        notes.append({"pitch": pitch, "beat": beat})

    mem_lines = []
    pending_lane = None
    pending_gap = 0.0

    for n in notes:
        p = n["pitch"]
        b = n["beat"]
        
        # 쉼표 처리
        if p in ["쉼", "쉼표", "r", "R", "rest", "Rest"]:
            if pending_lane is not None:
                # 이미 발생한 노트 뒤에 쉼표가 오면, 그 노트의 대기 시간에 더해줍니다.
                pending_gap += b
            else:
                # 아직 첫 노트가 안 나왔는데 쉼표가 오면, 0번 레인(가상 노트)으로 취급합니다.
                pending_lane = 0
                pending_gap = b
        else:
            # 계이름 처리
            lane = PITCH_MAP.get(p)
            if lane is None:
                print(f"경고: 알 수 없는 계이름 '{p}' 입니다. 임의로 레인1(도)로 처리합니다.")
                lane = 8
            
            # 이전에 들고 있던 노트를 파일에 기록 확정
            if pending_lane is not None:
                mem_lines.append(f"{pending_lane:X} {pending_gap:.2f}")
            
            pending_lane = lane
            # 새 노트의 기본 갭은 자신의 박자
            pending_gap = b 
            
    # 마지막 노트 기록
    if pending_lane is not None:
        mem_lines.append(f"{pending_lane:X} {pending_gap:.2f}")

    # 결과 저장
    with open(output_file, "w", encoding="utf-8") as f:
        for line in mem_lines:
            f.write(line + "\n")

    print(f"[성공] 총 {len(mem_lines)}개의 노트가 '{os.path.basename(output_file)}'에 저장되었습니다.")


if __name__ == "__main__":
    # 스크립트 실행 위치 기준
    base_dir = os.path.dirname(__file__)
    
    in_file = os.path.join(base_dir, INPUT_FILENAME)
    out_file = os.path.join(base_dir, OUTPUT_FILENAME)
    
    # 만약 입력 파일이 없으면 예시 템플릿 생성
    if not os.path.exists(in_file):
        with open(in_file, "w", encoding="utf-8") as f:
            f.write("# 악보를 보고 [계이름]과 [박자]를 적어주세요.\n")
            f.write("# (빈칸 띄어쓰기로 구분)\n\n")
            f.write("쉼표 32.0   # 8마디 전주 대기\n")
            f.write("솔 0.5\n")
            f.write("미 0.25\n")
            f.write("미 0.25\n")
            f.write("레 0.5\n")
            f.write("미 0.5\n")
            f.write("솔 0.5\n")
            f.write("솔 0.25\n")
            f.write("도 0.25\n")
            f.write("에 1.0     # 알 수 없는 글자는 '도'로 자동 변환됨\n")
            
        print(f"[안내] '{INPUT_FILENAME}' 파일이 없어서 예시 템플릿을 새로 생성했습니다!")
        print(f"생성된 {INPUT_FILENAME} 파일을 열어 내용을 수정하고 이 스크립트를 다시 실행해보세요.")
    else:
        convert(in_file, out_file)
