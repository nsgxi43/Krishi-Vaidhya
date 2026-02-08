# infer.py
"""
CNN inference module.
Responsible ONLY for image classification.
"""

import os
import pickle

# --- OPTIONAL MOCK FOR DEPENDENCIES ---
try:
    import numpy as np  # type: ignore
    import cv2  # type: ignore
    CV2_AVAILABLE = True
except ImportError as e:
    print(f"Computer Vision modules not found: {e}. Inference will be MOCKED.")
    CV2_AVAILABLE = False
    np = None
    cv2 = None

# --- OPTIONAL MOCK FOR TENSORFLOW ---
try:
    import tensorflow as tf  # type: ignore
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("TensorFlow not available. Image processing will run in MOCK mode.")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_PATH = os.path.join(BASE_DIR, "model", "plant_disease_model.h5")
LABEL_PATH = os.path.join(BASE_DIR, "model", "class_indices.pkl")

IMG_SIZE = 224
CONFIDENCE_THRESHOLD = 0.50
CONFIDENCE_GAP_THRESHOLD = 0.20

# Load once
if TF_AVAILABLE and CV2_AVAILABLE:
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
    except Exception as e:
        print(f"Failed to load model: {e}")
        model = None
else:
    model = None

try:
    with open(LABEL_PATH, "rb") as f:
        class_indices = pickle.load(f)
    idx_to_class = {v: k for k, v in class_indices.items()}
except Exception as e:
    print(f"⚠️ Failed to load labels: {e}")
    idx_to_class = {}

def _preprocess(image_path: str):
    if not CV2_AVAILABLE:
        raise ImportError("OpenCV not available")
        
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")

    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img = img.astype("float32") / 255.0
    return np.expand_dims(img, axis=0)


def run_inference(image_path: str) -> dict:
    if not TF_AVAILABLE or not CV2_AVAILABLE or model is None:
        # RETURN MOCK RESULT
        print("Returning MOCK inference result (Missing Deps/Model)")
        return {
            "crop": "MockCrop",
            "predicted_disease": "MockCrop___Healthy",
            "confidence": 0.99
        }

    image = _preprocess(image_path)
    preds = model.predict(image, verbose=0)[0]

    sorted_idx = preds.argsort()[::-1]
    top1, top2 = sorted_idx[0], sorted_idx[1]

    top1_conf = float(preds[top1])
    gap = top1_conf - float(preds[top2])

    if top1_conf < CONFIDENCE_THRESHOLD or gap < CONFIDENCE_GAP_THRESHOLD:
        raise ValueError("Low confidence or ambiguous prediction")

    label = idx_to_class[top1]

    return {
        "crop": label.split("___")[0],
        "predicted_disease": label,
        "confidence": top1_conf
    }
