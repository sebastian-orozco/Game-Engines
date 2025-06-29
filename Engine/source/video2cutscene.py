import cv2
import numpy as np
import json
import math
import os
import sys
from moviepy.editor import VideoFileClip

# === CHECK COMMAND LINE ARGUMENT ===
if len(sys.argv) < 2:
    print("Usage: python3 video2cutscene.py <video_file>")
    sys.exit(1)

# === CONFIGURATION ===
base_name = sys.argv[1].split('.mp4')[0]
video_path = f"../assets/videos/{sys.argv[1]}"
output_image = f"../assets/images/{base_name}.png"
output_json = f"../assets/images/{base_name}_metadata.json"
output_audio = f"../assets/music/{base_name}_audio.wav"
target_fps = 30

# SDL-safe limits
MAX_IMAGE_WIDTH = 16384
MAX_IMAGE_HEIGHT = 16384

# === OPEN VIDEO ===
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    raise RuntimeError("Could not open video.")

original_fps = cap.get(cv2.CAP_PROP_FPS)
frame_interval = original_fps / target_fps
frame_step = max(1, math.ceil(frame_interval))

tile_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
tile_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

# Estimate max columns and rows based on dimension caps
max_columns = max(1, MAX_IMAGE_WIDTH // tile_width)
max_rows = max(1, MAX_IMAGE_HEIGHT // tile_height)
max_frames = max_columns * max_rows

# === EXTRACT FRAMES ===
frames = []
frame_idx = 0

print("Extracting frames...")

while True:
    if len(frames) >= max_frames:
        print("Maximum number of frames reached. Video may terminate abruptly. Please lower the quality and try again.")
        break
    ret, frame = cap.read()
    if not ret:
        break
    if frame_idx % frame_step == 0:
        frames.append(frame)
    frame_idx += 1

cap.release()

if not frames:
    raise RuntimeError("No frames were extracted.")

# === CALCULATE GRID DIMENSIONS ===
columns = min(len(frames), max_columns)
rows = math.ceil(len(frames) / columns)

grid_width = columns * tile_width
grid_height = rows * tile_height
grid_image = np.zeros((grid_height, grid_width, 3), dtype=np.uint8)

print(f"Arranging {len(frames)} frames into grid: {columns} columns x {rows} rows")

# === TILE FRAMES INTO GRID ===
for idx, frame in enumerate(frames):
    r = idx // columns
    c = idx % columns
    y = r * tile_height
    x = c * tile_width
    grid_image[y:y + tile_height, x:x + tile_width] = frame

# === SAVE IMAGE ===
os.makedirs(os.path.dirname(output_image), exist_ok=True)
cv2.imwrite(output_image, grid_image)

# === WRITE METADATA JSON ===
metadata = {
    "filepath": output_image,
    "format": {
        "width": grid_width,
        "height": grid_height,
        "tileWidth": tile_width,
        "tileHeight": tile_height,
        "columns": columns,
        "rows": rows
    },
    "frames": {
        "video": list(range(len(frames)))
    }
}

with open(output_json, "w") as f:
    json.dump(metadata, f, indent=4)

# === EXTRACT AUDIO ===
print(f"Extracting audio to: {output_audio}")
os.makedirs(os.path.dirname(output_audio), exist_ok=True)

clip = VideoFileClip(video_path)
clip.audio.write_audiofile(output_audio)
clip.reader.close()
clip.audio.reader.close_proc()

# === DONE ===
print(f"Image saved to: {output_image}")
print(f"Metadata saved to: {output_json}")
print(f"Audio saved to: {output_audio}")
