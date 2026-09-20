import os
import time
from datetime import datetime
import numpy as np
from PIL import Image
import onnxruntime as ort
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

app = FastAPI()

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
ARTIFACTS_DIR = os.path.join(REPO_ROOT, "artifacts")
INBOX_DIR = os.path.join(REPO_ROOT, "misclassified_inbox")
os.makedirs(INBOX_DIR, exist_ok=True)

MODEL_PATH = os.path.join(ARTIFACTS_DIR, "model.onnx")
LABELS_PATH = os.path.join(ARTIFACTS_DIR, "labels.txt")

with open(LABELS_PATH, "r") as f:
    CLASSES = [line.strip() for line in f if line.strip()]

session = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])
input_name = session.get_inputs()[0].name
output_name = session.get_outputs()[0].name

@app.get("/api/classes")
def get_classes():
    return {"classes": CLASSES}

@app.post("/api/predict")
async def predict(file: UploadFile = File(...)):
    img = Image.open(file.file).convert("RGB")
    img_resized = img.resize((224, 224), Image.BILINEAR)

    arr = np.array(img_resized, dtype=np.float32) / 255.0
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    arr = (arr - mean) / std

    tensor = np.expand_dims(np.transpose(arr, (2, 0, 1)), axis=0).astype(np.float32)
    logits = session.run([output_name], {input_name: tensor})[0][0]
    exp_vals = np.exp(logits - np.max(logits))
    probs = exp_vals / np.sum(exp_vals)

    pred_idx = int(np.argmax(probs))
    return {
        "prediction": CLASSES[pred_idx],
        "confidence": float(probs[pred_idx]) * 100,
        "all_probs": {CLASSES[i]: float(probs[i]) * 100 for i in range(len(CLASSES))}
    }

@app.post("/api/feedback")
async def log_feedback(
    file: UploadFile = File(...),
    actual_label: str = Form(...)
):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    filename = f"{timestamp}_{actual_label}.jpg"
    filepath = os.path.join(INBOX_DIR, filename)

    img = Image.open(file.file).convert("RGB")
    img.save(filepath, "JPEG")
    return {"status": "success", "saved_as": filename}

# Serve static PWA files
STATIC_DIR = os.path.join(SCRIPT_DIR, "static")
os.makedirs(STATIC_DIR, exist_ok=True)
app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
