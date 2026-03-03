# pipeline.py
"""
Full AI pipeline:
CNN → Grad-CAM → LLM → Firestore
"""

import os

# --- OPTIONAL MOCK FOR TENSORFLOW ---
try:
    import tensorflow as tf  # type: ignore
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

from .infer import run_inference  # type: ignore
from .gradcam import run_gradcam  # type: ignore
from .llm import get_llm_explanation  # type: ignore
from db.diagnosis_service import create_diagnosis  # type: ignore
from location.location_service import normalize_location  # type: ignore

MODEL_PATH = os.path.join(BASE_DIR, "model", "plant_disease_model.h5")

# Load once
if TF_AVAILABLE:
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
    except Exception as e:
        print(f"Failed to load model: {e}")
        model = None
else:
    model = None


def run_pipeline(image_path: str, user_id: str, lat: float, lng: float) -> dict:
    """
    Run full AI pipeline with location integration.
    
    Args:
        image_path: Path to plant image
        user_id: User ID
        lat: Latitude
        lng: Longitude
    
    Returns:
        Complete diagnosis with location and nearby agri stores
    """
    # Step 0: Check for Local AI
    if not TF_AVAILABLE:
        print("Using Gemini Vision for diagnosis (Local AI missing)...")
        from .llm import analyze_image_with_gemini  # type: ignore
        
        # Cloud AI does everything in one shot
        cloud_result = analyze_image_with_gemini(image_path)
        
        cnn_output = {
            "crop": cloud_result.get("crop", "Unknown"),
            "predicted_disease": cloud_result.get("predicted_disease", "Unknown"),
            "confidence": cloud_result.get("confidence", 0.0),
            "explainability": cloud_result.get("explainability", {}),
            "userId": user_id
        }
        llm_output = cloud_result.get("llm", {})
        
        # Skip steps 1, 2, 3
    else: 
        # Step 1: CNN Inference
        cnn_output = run_inference(image_path)
        cnn_output["userId"] = user_id
        
        # Step 2: Grad-CAM Explainability
        try:
            cnn_output = run_gradcam(image_path, cnn_output, model)
        except Exception as e:
            print(f"Grad-CAM step failed: {e}. Adding fallback explainability.")
            cnn_output["explainability"] = {
                "method": "CNN Analysis",
                "summary": f"AI detected patterns consistent with {cnn_output.get('predicted_disease', 'unknown')}."
            }
        
        # Ensure explainability key exists before LLM step
        if "explainability" not in cnn_output:
            cnn_output["explainability"] = {
                "method": "CNN Analysis",
                "summary": f"Pattern analysis identified {cnn_output.get('predicted_disease', 'unknown')}."
            }
        
        # Step 3: LLM Explanation
        try:
            llm_output = get_llm_explanation(cnn_output)
        except Exception as e:
            print(f"LLM step failed: {e}. Using local explanation.")
            from .llm import _generate_local_explanation  # type: ignore
            llm_output = _generate_local_explanation(cnn_output)
    
    # Step 4: Normalize Location
    try:
        location = normalize_location(lat, lng)
    except Exception as e:
        print(f"Location normalization failed: {e}. Using defaults.")
        location = {"lat": lat, "lng": lng, "state": "Unknown", "district": "Unknown", "village": "Unknown"}
    
    # Step 5: Save to Firestore
    try:
        diagnosis_id = create_diagnosis(
            user_id=cnn_output["userId"],
            crop=cnn_output["crop"],
            disease=cnn_output["predicted_disease"],
            confidence=cnn_output["confidence"],
            explainability=cnn_output.get("explainability", {}),
            location=location,
            llm=llm_output
        )
    except Exception as e:
        print(f"Failed to save diagnosis: {e}")
        diagnosis_id = "local_diagnosis"
    
    # Step 6: Get Nearby Agri Stores
    try:
        from .agri_store_service import get_nearby_agri_stores  # type: ignore
        agri_stores = get_nearby_agri_stores(location, radius_km=10)
    except Exception as e:
        print(f"Failed to fetch agri stores: {e}")
        agri_stores = []
    
    # Final output
    final_output = {
        **cnn_output,
        "llm": llm_output,
        "location": location,
        "diagnosisId": diagnosis_id,
        "nearbyAgriStores": agri_stores
    }
    
    return final_output


if __name__ == "__main__":
    result = run_pipeline(
        image_path=os.path.join(BASE_DIR, "test_image.JPG"),
        user_id="9999999999",
        lat=12.9716,
        lng=77.5946
    )
    
    print("\nPIPELINE RESULT\n")
    print(result)