# kvb/db/diagnosis_service.py

from datetime import datetime
from firebase_admin import firestore
from .firebase_init import db


def create_diagnosis(
    user_id: str,
    crop: str,
    disease: str,
    confidence: float,
    explainability: dict,
    location: dict,
    llm: dict | None = None
):
    """
    Create a diagnosis record with location.
    
    Args:
        user_id: User ID
        crop: Crop name
        disease: Predicted disease
        confidence: Model confidence (0-1)
        explainability: Grad-CAM output
        location: Normalized location dict (lat, lng, state, district, village, geohash)
        llm: Optional LLM explanation
    
    Returns:
        Document ID
    """
    doc = {
        "userId": user_id,
        "crop": crop,
        "disease": disease,
        "confidence": confidence,
        "explainability": explainability,
        "location": location,
        "createdAt": firestore.SERVER_TIMESTAMP,
    }
    
    if db is None:
        print("⚠️ Database not available. Returning mock diagnosis ID.")
        return "mock_diagnosis_id_456"
    
    if llm is not None:
        doc["llm"] = llm
    
    try:
        ref = db.collection("diagnoses").document()
        ref.set(doc)
        return ref.id
    except Exception as e:
        print(f"Failed to save diagnosis to DB: {e}")
        return "mock_diagnosis_id_error"