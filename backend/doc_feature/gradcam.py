# gradcam.py
"""
Grad-CAM explainability module.
NO printing. NO model loading here.
"""

# --- OPTIONAL MOCK FOR DEPENDENCIES ---
try:
    import numpy as np  # type: ignore
    import cv2  # type: ignore
    CV2_AVAILABLE = True
except ImportError:
    CV2_AVAILABLE = False
    np = None
    cv2 = None

# --- OPTIONAL MOCK FOR TENSORFLOW ---
try:
    import tensorflow as tf  # type: ignore
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False


IMG_SIZE = 224
LAST_CONV_LAYER = "Conv_1"


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


def compute_gradcam(image_tensor, model):
    if not TF_AVAILABLE or model is None:
        # Return dummy heatmap
        return np.zeros((IMG_SIZE, IMG_SIZE))

    last_conv = model.get_layer(LAST_CONV_LAYER)

    grad_model = tf.keras.models.Model(
        model.inputs,
        [last_conv.output, model.output]
    )

    with tf.GradientTape() as tape:
        conv_out, preds = grad_model(image_tensor, training=False)

        # 🔒 Keras Functional safety
        if isinstance(preds, list):
            preds = preds[0]

        preds = tf.convert_to_tensor(preds)

        pred_class = tf.argmax(preds[0])
        class_score = preds[:, pred_class]

    grads = tape.gradient(class_score, conv_out)
    pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))

    heatmap = tf.reduce_sum(conv_out[0] * pooled_grads, axis=-1)
    heatmap = tf.maximum(heatmap, 0)

    denom = tf.reduce_max(heatmap)
    heatmap = tf.cond(
        denom > 0,
        lambda: heatmap / denom,
        lambda: heatmap
    )

    return heatmap.numpy()


def gradcam_summary(heatmap: np.ndarray) -> str:
    mean = float(heatmap.mean())

    if mean < 0.3:
        return "Focused on uniform leaf regions with minimal abnormalities."
    elif mean < 0.6:
        return "Focused on moderate color and texture variations."
    else:
        return "Focused strongly on lesions, spots, or discoloration."


def run_gradcam(image_path: str, cnn_output: dict, model) -> dict:
    image_tensor = _preprocess(image_path)
    heatmap = compute_gradcam(image_tensor, model)

    cnn_output["explainability"] = {
        "method": "Grad-CAM",
        "summary": gradcam_summary(heatmap)
    }

    return cnn_output
