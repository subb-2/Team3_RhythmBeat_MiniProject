import os
import json
from datetime import datetime

LEADERBOARD_FILE = os.path.join(os.path.dirname(__file__), "leaderboard.json")

def load_leaderboard():
    if not os.path.exists(LEADERBOARD_FILE):
        return []
    try:
        with open(LEADERBOARD_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def save_score(name, score, max_combo, photo_path=""):
    data = load_leaderboard()
    entry = {
        "name": name,
        "score": score,
        "max_combo": max_combo,
        "photo_path": photo_path,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    data.append(entry)
    # 점수 내림차순 정렬
    data.sort(key=lambda x: x.get("score", 0), reverse=True)
    # 최대 10위까지만 저장
    data = data[:10]
    
    try:
        with open(LEADERBOARD_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
    except Exception as e:
        print(f"Failed to save leaderboard: {e}")

def reset_leaderboard():
    try:
        with open(LEADERBOARD_FILE, "w", encoding="utf-8") as f:
            json.dump([], f, ensure_ascii=False, indent=4)
    except Exception as e:
        print(f"Failed to reset leaderboard: {e}")

