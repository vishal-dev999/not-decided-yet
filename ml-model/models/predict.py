import os
import sys
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LABELS_PATH = os.path.join(SCRIPT_DIR, "labels.txt")
WEIGHTS_PATH = os.path.join(SCRIPT_DIR, "mobilenet_ewaste.pth")

# 1. Load labels
with open(LABELS_PATH, "r") as f:
    class_names = [line.strip() for line in f if line.strip()]

# 2. Build model and load trained weights
model = models.mobilenet_v3_small(weights=None)
in_features = model.classifier[3].in_features
model.classifier[3] = nn.Linear(in_features, len(class_names))
model.load_state_dict(torch.load(WEIGHTS_PATH, map_location="cpu"))
model.eval()

# 3. Preprocessing
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

def predict(image_path):
    image = Image.open(image_path).convert("RGB")
    tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        outputs = model(tensor)
        probabilities = torch.nn.functional.softmax(outputs[0], dim=0)

    top_prob, top_class = torch.topk(probabilities, 3)
    print(f"\n--- Prediction for: {os.path.basename(image_path)} ---")
    for i in range(top_prob.size(0)):
        idx = top_class[i].item()
        print(f"{i+1}. {class_names[idx]}: {top_prob[i].item()*100:.2f}%")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python models/predict.py <path_to_image>")
    else:
        predict(sys.argv[1])
