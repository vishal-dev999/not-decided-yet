import os
import sys
import numpy as np
import onnxruntime as ort
from PIL import Image

def test_model(image_path, model_path="model.onnx", labels_path="labels.txt"):
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model not found: {model_path}")
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Sample image not found: {image_path}")

    # 1. Load labels if present
    labels = []
    if os.path.exists(labels_path):
        with open(labels_path, "r") as f:
            labels = [line.strip() for line in f if line.strip()]

    # 2. Open image and resize to 224x224 RGB
    img = Image.open(image_path).convert("RGB")
    img = img.resize((224, 224))

    # 3. Convert to float numpy array and normalize: ToTensor() -> (val / 255.0)
    arr = np.array(img, dtype=np.float32) / 255.0

    # 4. Standard ImageNet normalization: (arr - mean) / std
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    arr = (arr - mean) / std

    # 5. Convert HWC -> CHW -> NCHW: (1, 3, 224, 224)
    arr = np.transpose(arr, (2, 0, 1))
    input_tensor = np.expand_dims(arr, axis=0).astype(np.float32)

    # 6. Initialize ONNX Runtime Session
    session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name

    # 7. Run inference
    raw_outputs = session.run([output_name], {input_name: input_tensor})[0]

    # 8. Compute Softmax probabilities
    logits = raw_outputs[0]
    exp_vals = np.exp(logits - np.max(logits))
    probs = exp_vals / np.sum(exp_vals)

    pred_idx = int(np.argmax(probs))
    pred_label = labels[pred_idx] if pred_idx < len(labels) else f"Class {pred_idx}"

    print(f"\nImage: {image_path}")
    print(f"Predicted Material: {pred_label}")
    print(f"Confidence: {probs[pred_idx] * 100:.2f}%\n")

    print("Class Probabilities:")
    for i, p in enumerate(probs):
        name = labels[i] if i < len(labels) else f"Class {i}"
        print(f"  [{i}] {name:<20}: {p * 100:.2f}%")

if __name__ == "__main__":
    # Pass an image from your val/train dataset or command line arg
    default_img = "../../datasets/images/val"
    if len(sys.argv) > 1:
        img_file = sys.argv[1]
    else:
        # Pick the first available image from the dataset if no path is given
        found = None
        for root, _, files in os.walk(default_img):
            for f in files:
                if f.lower().endswith((".jpg", ".png", ".jpeg")):
                    found = os.path.join(root, f)
                    break
            if found:
                break
        img_file = found or "sample.jpg"

    test_model(img_file)
