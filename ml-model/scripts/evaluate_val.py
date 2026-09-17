import os
import torch
import numpy as np
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader
from PIL import Image

def rgb_loader(path):
    with open(path, "rb") as f:
        img = Image.open(f)
        return img.convert("RGB")

def main():
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

    DATA_DIR = os.path.join(REPO_ROOT, "datasets", "images")
    VAL_DIR = os.path.join(DATA_DIR, "val")
    WEIGHTS_PATH = os.path.join(SCRIPT_DIR, "mobilenet_ewaste.pth")
    LABELS_PATH = os.path.join(SCRIPT_DIR, "labels.txt")

    with open(LABELS_PATH, "r") as f:
        class_names = [line.strip() for line in f if line.strip()]
    num_classes = len(class_names)

    val_transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    val_dataset = datasets.ImageFolder(VAL_DIR, transform=val_transform, loader=rgb_loader)
    val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False, num_workers=0)

    # Reconstruct MobileNetV3 Small
    model = models.mobilenet_v3_small(weights=None)
    in_features = model.classifier[3].in_features
    model.classifier[3] = torch.nn.Linear(in_features, num_classes)
    model.load_state_dict(torch.load(WEIGHTS_PATH, map_location="cpu"))
    model.eval()

    all_preds = []
    all_targets = []

    with torch.no_grad():
        for inputs, targets in val_loader:
            outputs = model(inputs)
            _, preds = torch.max(outputs, 1)
            all_preds.extend(preds.cpu().numpy())
            all_targets.extend(targets.cpu().numpy())

    all_preds = np.array(all_preds)
    all_targets = np.array(all_targets)

    # 1. Confusion Matrix Computation
    conf_matrix = np.zeros((num_classes, num_classes), dtype=int)
    for t, p in zip(all_targets, all_preds):
        conf_matrix[t, p] += 1

    print("\n" + "=" * 55)
    print("                CONFUSION MATRIX")
    print("=" * 55)
    header = f"{'True \\ Pred':<25}" + "".join([f"[{i}]".rjust(6) for i in range(num_classes)])
    print(header)
    for i, name in enumerate(class_names):
        row_str = f"[{i}] {name[:20]:<20}" + "".join([f"{val:>6}" for val in conf_matrix[i]])
        print(row_str)

    # 2. Per-Class Metrics
    print("\n" + "=" * 55)
    print("             PER-CLASS PERFORMANCE")
    print("=" * 55)
    print(f"{'Class Name':<25} | {'Prec (%)':<9} | {'Recall (%)':<10} | {'F1'}")
    print("-" * 55)

    for i in range(num_classes):
        tp = conf_matrix[i, i]
        fp = conf_matrix[:, i].sum() - tp
        fn = conf_matrix[i, :].sum() - tp

        prec = (tp / (tp + fp)) * 100 if (tp + fp) > 0 else 0.0
        rec = (tp / (tp + fn)) * 100 if (tp + fn) > 0 else 0.0
        f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0.0

        print(f"{class_names[i]:<25} | {prec:>8.1f}% | {rec:>9.1f}% | {f1/100:.2f}")

    # 3. Exact Misclassified Files
    print("\n" + "=" * 55)
    print("              MISCLASSIFIED SAMPLES")
    print("=" * 55)
    misclassified_count = 0
    for idx, (target, pred) in enumerate(zip(all_targets, all_preds)):
        if target != pred:
            misclassified_count += 1
            file_path, _ = val_dataset.samples[idx]
            file_name = os.path.basename(file_path)
            true_label = class_names[target]
            pred_label = class_names[pred]
            print(f"[{misclassified_count}] {file_name}")
            print(f"    Expected : {true_label}")
            print(f"    Predicted: {pred_label}\n")

    if misclassified_count == 0:
        print("Flawless run! Zero misclassified samples.")

if __name__ == "__main__":
    main()
