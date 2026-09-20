# RecyLink Local AI Classifier (ONNX Engine)

This directory contains the machine learning model files, asset definitions, and inference logic powering the offline-first e-waste classification engine in **RecyLink**.

---

## 🚀 Overview
RecyLink uses an embedded ONNX Runtime (`onnxruntime_v2`) to execute image classification directly on-device. This ensures that field collectors can accurately identify, categorize, and price scrap items instantly—even in remote areas with zero internet connectivity.

---

## 📂 Directory Contents
* `model.onnx` — The optimized ONNX neural network model weights.
* `labels.txt` — Class label mappings corresponding to canonical e-waste categories.
* `price_benchmark.json` — Baseline market valuation rates and pricing bounds.

---

## 🏷️ Canonical Categories & Outputs
The model evaluates images against 10 strict classes, mapped directly to the backend pricing engine:

1. `MOTHERBOARD_HIGH_GRADE` (High Grade PCB)
2. `POWER_SUPPLY_LOW_GRADE` (Low Grade PCB / SMPS)
3. `BATTERY_LITHIUM_PORTABLE` (Portable Lithium-ion Batteries)
4. `LEAD_ACID` (Lead-Acid Batteries)
5. `CRT_MONITOR` (CRT Monitors)
6. `LCD_PANEL_INTACT` (LCD / LED Flat Panel Displays)
7. `MIXED_EWASTE_CASING` (Mixed E-Waste Plastics & Casings)
8. `COPPER_HEAVY_INSULATED` (Insulated Copper Heavy Wiring)
9. `ALUMINIUM_WIRE` (Aluminium Scrap Wiring)
10. `NON_E_WASTE` (Fallback category for invalid or non-recyclable items)

---

## ⚙️ Inference & Preprocessing Pipeline
To match the training distribution of the underlying model, all captured images undergo the following pre-processing steps on a background compute isolate:
1. **Decoding & Resizing:** Decoded from raw image bytes and resized uniformly to $224 \times 224$ pixels.
2. **Channel Rearrangement:** Converted into a NCHW tensor layout (`[1, 3, 224, 224]`).
3. **Normalization:** Standard ImageNet normalization applied using standard mean (`[0.485, 0.456, 0.406]`) and standard deviation (`[0.229, 0.224, 0.225]`) tensors.

---

## 🛡️ Guardrails & Confidence Thresholds
* **Confidence Threshold:** Enforces a minimum confidence score of **65%**.
* **Invalid Handling:** If an item falls below the threshold or is classified as `NON_E_WASTE`, client-side UI guardrails block lot creation, prompting the collector to retake the photo or reject the non-scrap item.
