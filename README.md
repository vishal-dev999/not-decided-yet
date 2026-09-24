<div align="center">

# ♻️ RecyLink
### Offline-First E-Waste Management & Local AI Classification Platform

[![Built for Hackathon](https://img.shields.io/badge/Status-Hackathon%20Project-blue?style=flat-square)]()
[![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?style=flat-square&logo=flutter)]()
[![ONNX Runtime](https://img.shields.io/badge/AI-ONNX%20Runtime-00599C?style=flat-square)]()
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

</div>

---

## 🚀 About the Project
**RecyLink** is an offline-first mobile platform built to streamline informal e-waste collection, grading, and transparent pricing. Designed for field operators operating in low-connectivity environments, RecyLink integrates an embedded **ONNX Runtime** to execute high-accuracy image classification locally on-device. This ensures instant material valuation, zero-latency feedback, and reliable local queuing with automated background synchronization once connectivity is restored.

---

## 🛠️ Core Technical Architecture
* **On-Device Edge AI:** Custom-trained neural network weights compiled to ONNX, executing zero-latency image preprocessing and inference ($224 \times 224$ NCHW tensors).
* **Offline-First Synchronization:** Local SQLite storage acting as a Single Source of Truth (SSOT) with robust background sync workers.
* **Multilingual Support:** Full dynamic localization across English, Hindi, and Marathi with embedded Text-to-Speech (TTS) integration.
* **Rigorous Guardrails:** Built-in confidence thresholds ($65\%$) and non-e-waste rejection filters to maintain data integrity during bulk lot creation.

---

## 👥 Team ReNova

RecyLink is engineered and conceptualized by **Team ReNova** for the hackathon. Listed in strict alphabetical order:

| Team Member | Role & Core Contributions |
| :--- | :--- |
| **Astha** | Collector-side Frontend Architecture & UI Implementation |
| **Priyanshu** | UI/UX Design & Creative Direction |
| **Shreyansu** | Backend Infrastructure & API Services |
| **Subham** | UI/UX Design & Visual Prototyping |
| **Swastik** | UI/UX Design & App Logo Branding |
| **Vishal** | Dataset Curation, AI/ML Model Training (ONNX), & Git Repository / Merge Conflict Management |

---

## 📂 Repository Structure
* `/mobile-app` — Flutter application source code (Screens, State Management, Localization).
* `/ml-model` — ONNX model weights, label mappings, and benchmark configurations.
* `/datasets` — Data source provenance documentation (`DATA.md`) and dataset attribution manifests.
* `/backend` — Server-side endpoints and synchronization services.

---

## 📜 License
This project is open-source and available under the terms of the [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE) license.
