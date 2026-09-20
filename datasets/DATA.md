# Dataset & Data Sources Documentation

This document outlines the external data sources, processed datasets, and datasets utilized for training the custom ONNX image classification model and prototyping the RecyLink platform.

---

## 1. Processed & Cleaned Image Dataset (Hugging Face)
The final curated, cropped, and restructured image dataset containing the processed training, validation, and test splits used for our ONNX model is hosted publicly:
* **Repository Link:** [Hugging Face - SIH20226_PS-229 E-waste Classification Dataset](https://huggingface.co/datasets/CRAZY-boy/SIH20226_PS-229_E-waste-classification-dataset)

---

## 2. Machine Learning Training Datasets (Roboflow Universe)
The raw image data used for training and tuning our e-waste classification model was compiled from multiple open-source Roboflow Universe projects. **Note:** The raw images from these sources were not used directly; they were heavily filtered, manually handpicked, cropped, and restructured to fit our specific canonical material categories.

* **E-Waste Project**
  * **Source:** [Roboflow Universe - E-Waste Project](https://universe.roboflow.com/satwikajagarlamudi-4-gmail-com/e-waste-project)
  * **License:** CC BY 4.0

* **e3 (Exida)**
  * **Source:** [Roboflow Universe - e3](https://universe.roboflow.com/ewaste-management-zjiiq/e3-exida)
  * **License:** CC BY 4.0

* **eloop_vm**
  * **Source:** [Roboflow Universe - eloop_vm](https://universe.roboflow.com/nicoles-workspace-rwjrh/eloop_vm)
  * **License:** CC BY 4.0

* **Ewaste-Detection**
  * **Source:** [Roboflow Universe - Ewaste-Detection](https://universe.roboflow.com/palanisamy/ewaste-detection-2kxmr)
  * **License:** CC BY 4.0

* **West Classification GFNPA (v3)**
  * **Source:** [Roboflow Universe - West Classification](https://universe.roboflow.com/code2gether/west-classification-gfnpa/dataset/3)
  * **License:** CC BY 4.0

---

## 3. UI Mockups & Stock Imagery
* **Source:** Stock photography and reference imagery sourced via Google Images and public domain libraries.
* **Purpose:** Utilized exclusively for initial UI prototyping, user flow testing, and presentation assets.
