import os
import torch
import torchvision.models as models
import torch.nn as nn

try:
    import litert_torch as ai_edge_torch
except ImportError:
    import ai_edge_torch

CANDIDATE_PATHS = [
    "models/mobilenet_ewaste.pth",
    "../ml/models/mobilenet_ewaste.pth",
    "mobilenet_ewaste.pth"
]

CHECKPOINT_PATH = None
for p in CANDIDATE_PATHS:
    if os.path.exists(p):
        CHECKPOINT_PATH = p
        break

if not CHECKPOINT_PATH:
    raise FileNotFoundError("Could not find mobilenet_ewaste.pth! Check the file path.")

OUTPUT_TFLITE = "model.tflite"
NUM_CLASSES = 6

print(f"Loading checkpoint: {CHECKPOINT_PATH} ...")

# 1. Use mobilenet_v3_small (matches the checkpoint weights)
model = models.mobilenet_v3_small(weights=None)
model.classifier[3] = nn.Linear(model.classifier[3].in_features, NUM_CLASSES)

# 2. Load weights
checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu")
if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
    state_dict = checkpoint["model_state_dict"]
elif isinstance(checkpoint, dict) and "state_dict" in checkpoint:
    state_dict = checkpoint["state_dict"]
else:
    state_dict = checkpoint

model.load_state_dict(state_dict)
model.eval()

# 3. Export to TFLite
print("Exporting MobileNetV3-Small to TFLite flatbuffer...")
sample_input = (torch.randn(1, 3, 224, 224),)

edge_model = ai_edge_torch.convert(model, sample_input)
edge_model.export(OUTPUT_TFLITE)

print(f"\nExport successful! Generated: {OUTPUT_TFLITE}")
