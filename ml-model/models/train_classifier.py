import os
import time
import torch
import torch.nn as nn
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader

def main():
    # 1. Directory resolution
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

    DATA_DIR = os.path.join(REPO_ROOT, "datasets", "images")
    TRAIN_DIR = os.path.join(DATA_DIR, "train")
    VAL_DIR = os.path.join(DATA_DIR, "val")
    OUTPUT_DIR = SCRIPT_DIR
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    BATCH_SIZE = 32
    EPOCHS = 12
    LEARNING_RATE = 1e-3
    DEVICE = torch.device("cpu")

    # Preprocessing transforms (MobileNet standard input)
    data_transforms = {
        "train": transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(15),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        "val": transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])
    }

    # 2. Load datasets with num_workers=0 for safe CPU execution
    train_dataset = datasets.ImageFolder(TRAIN_DIR, transform=data_transforms["train"])
    val_dataset = datasets.ImageFolder(VAL_DIR, transform=data_transforms["val"])

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)

    class_names = train_dataset.classes
    num_classes = len(class_names)

    print(f"Detected {num_classes} classes: {class_names}")
    print(f"Training samples: {len(train_dataset)} | Validation samples: {len(val_dataset)}")

    # Save class labels
    labels_path = os.path.join(OUTPUT_DIR, "labels.txt")
    with open(labels_path, "w") as f:
        for name in class_names:
            f.write(f"{name}\n")
    print(f"Saved {labels_path}")

# 1. Load backbone
    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)

# 2. Freeze all early layers (edges, textures, color gradients)
    for param in model.parameters():
        param.requires_grad = False

# 3. Unfreeze the last 3 depthwise-separable blocks of the backbone
    for block in model.features[-3:]:
        for param in block.parameters():
            param.requires_grad = True

# 4. Replace final classification head
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    model.to(DEVICE)

# 5. Differential Learning Rates:
# Train the newly initialized head faster, and gently fine-tune the backbone
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam([
        {"params": model.features[-3:].parameters(), "lr": 1e-4},
        {"params": model.classifier.parameters(), "lr": 1e-3}
    ])

# Train for 10-12 epochs
    EPOCHS = 12

    # 4. Train and validate
    print("\nStarting training loop...")
    start_time = time.time()

    for epoch in range(EPOCHS):
        # --- Training Phase ---
        model.train()
        train_loss, train_correct, train_total = 0.0, 0, 0

        for inputs, labels in train_loader:
            inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
            optimizer.zero_grad()

            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * inputs.size(0)
            _, preds = torch.max(outputs, 1)
            train_correct += (preds == labels).sum().item()
            train_total += labels.size(0)

        epoch_train_loss = train_loss / train_total
        epoch_train_acc = (train_correct / train_total) * 100

        # --- Validation Phase ---
        model.eval()
        val_loss, val_correct, val_total = 0.0, 0, 0

        with torch.no_grad():
            for inputs, labels in val_loader:
                inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
                outputs = model(inputs)
                loss = criterion(outputs, labels)

                val_loss += loss.item() * inputs.size(0)
                _, preds = torch.max(outputs, 1)
                val_correct += (preds == labels).sum().item()
                val_total += labels.size(0)

        epoch_val_loss = val_loss / val_total
        epoch_val_acc = (val_correct / val_total) * 100

        print(f"Epoch {epoch+1}/{EPOCHS} | "
              f"Train Loss: {epoch_train_loss:.4f} Acc: {epoch_train_acc:.1f}% | "
              f"Val Loss: {epoch_val_loss:.4f} Acc: {epoch_val_acc:.1f}%")

    total_time = time.time() - start_time
    print(f"\nRun finished in {total_time/60:.1f} minutes.")

    # 5. Save weights
    weights_path = os.path.join(OUTPUT_DIR, "mobilenet_ewaste.pth")
    torch.save(model.state_dict(), weights_path)
    print(f"Saved {weights_path}")

if __name__ == "__main__":
    main()
