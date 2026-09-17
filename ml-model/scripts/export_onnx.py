import os
import torch
import torch.nn as nn
from torchvision import models
import onnx

def export():
    # 1. Directory resolution
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
    ARTIFACTS_DIR = os.path.join(REPO_ROOT, "artifacts")
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)

    labels_path = os.path.join(ARTIFACTS_DIR, "labels.txt")
    weights_path = os.path.join(ARTIFACTS_DIR, "mobilenet_ewaste.pth")
    onnx_path = os.path.join(ARTIFACTS_DIR, "model.onnx")
    data_path = f"{onnx_path}.data"

    if not os.path.exists(weights_path):
        raise FileNotFoundError(f"Missing weights file at: {weights_path}")
    if not os.path.exists(labels_path):
        raise FileNotFoundError(f"Missing labels file at: {labels_path}")

    # 2. Clean previous export files
    if os.path.exists(onnx_path):
        os.remove(onnx_path)
    if os.path.exists(data_path):
        os.remove(data_path)

    # 3. Read classes
    with open(labels_path, "r") as f:
        classes = [line.strip() for line in f if line.strip()]
    num_classes = len(classes)

    # 4. Reconstruct MobileNetV3 Small architecture
    model = models.mobilenet_v3_small(weights=None)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    model.load_state_dict(torch.load(weights_path, map_location="cpu"))
    model.eval()

    dummy_input = torch.randn(1, 3, 224, 224, requires_grad=False)

    # 5. Export to ONNX with opset 18
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input": {0: "batch_size"},
            "output": {0: "batch_size"}
        }
    )

    # 6. Force inline storage into a single standalone .onnx file
    onnx_model = onnx.load(onnx_path, load_external_data=True)
    onnx.save_model(
        onnx_model,
        onnx_path,
        save_as_external_data=False
    )

    # 7. Remove external .data file if created
    if os.path.exists(data_path):
        os.remove(data_path)

    print(f"Export complete -> Single standalone file saved to: {onnx_path}")

if __name__ == "__main__":
    export()
