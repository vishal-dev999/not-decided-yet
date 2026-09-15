import os
import shutil
import random

# Set seed for reproducible splits
random.seed(42)

# Paths relative to where you run the script (e.g. from datasets/images/)
BASE_DIR = "."
TRAIN_DIR = os.path.join(BASE_DIR, "train")
VAL_DIR = os.path.join(BASE_DIR, "val")

SPLIT_RATIO = 0.20  # 20% to val, 80% remains in train

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

if not os.path.exists(TRAIN_DIR):
    raise FileNotFoundError(f"Train directory not found at: {TRAIN_DIR}")

os.makedirs(VAL_DIR, exist_ok=True)

# Get all class subdirectories in train
classes = [
    d for d in os.listdir(TRAIN_DIR)
    if os.path.isdir(os.path.join(TRAIN_DIR, d)) and not d.startswith(".")
]

print(f"Found {len(classes)} classes in {TRAIN_DIR}\n")

total_moved = 0
total_remaining = 0

for cls in sorted(classes):
    src_cls_dir = os.path.join(TRAIN_DIR, cls)
    dst_cls_dir = os.path.join(VAL_DIR, cls)
    os.makedirs(dst_cls_dir, exist_ok=True)

    # Collect valid image files
    images = [
        f for f in os.listdir(src_cls_dir)
        if os.path.isfile(os.path.join(src_cls_dir, f))
        and os.path.splitext(f.lower())[1] in VALID_EXTENSIONS
    ]

    total_images = len(images)
    if total_images == 0:
        print(f"[{cls}] Skipped: 0 images found")
        continue

    # Determine 20% sample count
    val_count = int(total_images * SPLIT_RATIO)
    # Ensure at least 1 image goes to val if there are images available
    val_count = max(1, val_count) if total_images > 1 else 0

    val_images = random.sample(images, val_count)

    # Move selected files from train to val
    for img_name in val_images:
        src_file = os.path.join(src_cls_dir, img_name)
        dst_file = os.path.join(dst_cls_dir, img_name)
        shutil.move(src_file, dst_file)

    train_count = total_images - val_count
    total_moved += val_count
    total_remaining += train_count

    print(f"[{cls:30s}] Total: {total_images:3d} ➔ Train: {train_count:3d} (80%) | Val: {val_count:2d} (20%)")

print("\n--- Split Summary ---")
print(f"Total training images:   {total_remaining}")
print(f"Total validation images: {total_moved}")
