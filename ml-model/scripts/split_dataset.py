import os
import random
import shutil

def split_train_val(val_ratio=0.2, seed=42):
    random.seed(seed)

    # 1. Directory resolution
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

    # DATA_DIR matches train_classifier.py
    data_dir = os.path.abspath(os.path.join(REPO_ROOT, "..", "datasets", "images"))
    train_dir = os.path.join(data_dir, "train")
    val_dir = os.path.join(data_dir, "val")

    if not os.path.exists(train_dir):
        raise FileNotFoundError(f"Train directory not found at: {train_dir}")

    os.makedirs(val_dir, exist_ok=True)
    valid_exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

    # 2. Reset Step: Move any existing val images back to train first
    if os.path.exists(val_dir):
        for cls in os.listdir(val_dir):
            val_cls_dir = os.path.join(val_dir, cls)
            train_cls_dir = os.path.join(train_dir, cls)
            if os.path.isdir(val_cls_dir):
                os.makedirs(train_cls_dir, exist_ok=True)
                for f in os.listdir(val_cls_dir):
                    if os.path.splitext(f.lower())[1] in valid_exts:
                        shutil.move(os.path.join(val_cls_dir, f), os.path.join(train_cls_dir, f))

    classes = [d for d in os.listdir(train_dir) if os.path.isdir(os.path.join(train_dir, d))]
    print(f"Found {len(classes)} classes in {train_dir}\n")

    # 3. Perform fresh 80:20 split
    for cls in sorted(classes):
        src_cls_dir = os.path.join(train_dir, cls)
        dst_cls_dir = os.path.join(val_dir, cls)
        os.makedirs(dst_cls_dir, exist_ok=True)

        images = [f for f in os.listdir(src_cls_dir) if os.path.splitext(f.lower())[1] in valid_exts]
        random.shuffle(images)

        val_count = int(len(images) * val_ratio)
        val_images = images[:val_count]

        for img_name in val_images:
            shutil.move(
                os.path.join(src_cls_dir, img_name),
                os.path.join(dst_cls_dir, img_name)
            )

        print(f"Class '{cls}': {len(images) - val_count} train | {val_count} val")

    print("\nDataset split complete!")

if __name__ == "__main__":
    split_train_val()
