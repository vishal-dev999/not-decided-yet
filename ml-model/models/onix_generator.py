import torch
import torchvision.models as models
import torch.nn as nn
#new_comment
NUM_CLASSES = 6
CHECKPOINT_PATH = "models/mobilenet_ewaste.pth"  # adjust path if inside models/
OUTPUT_ONNX = "model.onnx"

model = models.mobilenet_v3_small(weights=None)
model.classifier[3] = nn.Linear(model.classifier[3].in_features, NUM_CLASSES)

checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu")
if isinstance(checkpoint, dict) and "state_dict" in checkpoint:
    checkpoint = checkpoint["state_dict"]
elif isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
    checkpoint = checkpoint["model_state_dict"]

model.load_state_dict(checkpoint)
model.eval()

dummy_input = torch.randn(1, 3, 224, 224)

torch.onnx.export(
    model,
    dummy_input,
    OUTPUT_ONNX,
    input_names=["input"],
    output_names=["output"],
    opset_version=17,
    dynamo=False  # <-- Forces self-contained single-file export (no .data sidecar)
)

print(f"Exported clean, self-contained {OUTPUT_ONNX}")
