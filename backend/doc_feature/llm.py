# llm.py
"""
LLM reasoning module.
Consumes ONLY verified ML + Grad-CAM output.
"""

import os
import json
import requests  # type: ignore
import base64

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Gemini model fallback chain: try newer models first, fall back to older ones
GEMINI_MODELS = ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-1.5-flash"]
MODEL_NAME = GEMINI_MODELS[0]  # Default model
API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"
API_URL = f"{API_BASE}/{MODEL_NAME}:generateContent"
MIN_CONFIDENCE = 0.60

import time

def analyze_image_with_gemini(image_path: str) -> dict:
    """
    Fallback: Diagnose crop disease directly using Gemini Vision.
    """
    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY not set. Cannot use Cloud AI.")
        raise ValueError("Missing Gemini API Key")

    try:
        # 1. Encode image to base64
        with open(image_path, "rb") as f:
            image_data = base64.b64encode(f.read()).decode("utf-8")

        prompt = """
        You are an expert plant pathologist AI.
        Analyze this plant image.
        
        1. Identify the crop.
        2. Identify the disease (if any) or if it is healthy.
        3. Estimate confidence (0.0 to 1.0).
        4. Provide treatment/prevention info.

        Return STRICT JSON with these fields:
        {
          "crop": "Crop Name",
          "predicted_disease": "Crop___Disease_Name",
          "confidence": 0.95,
          "explainability": {
            "method": "Gemini Vision",
            "summary": "Visual analysis of leaf symptoms."
          },
          "llm": {
            "disease_overview": "Summary of the disease...",
            "why_this_prediction": "Visual evidence...",
            "chemical_treatments": ["..."],
            "organic_treatments": ["..."],
            "prevention_tips": ["..."]
          }
        }
        """

        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": image_data
                            }
                        }
                    ]
                }
            ]
        }

        # RETRY LOGIC with model fallback
        max_retries = 3
        last_error = "Unknown Error"
        
        for attempt in range(max_retries):
            # Try each model in the fallback chain
            current_model = GEMINI_MODELS[min(attempt, len(GEMINI_MODELS) - 1)]
            current_url = f"{API_BASE}/{current_model}:generateContent"
            
            try:
                response = requests.post(
                    f"{current_url}?key={GEMINI_API_KEY}",
                    headers={"Content-Type": "application/json"},
                    data=json.dumps(payload),
                    timeout=30
                )
                
                if response.status_code == 429:
                    wait_time = 2 ** (attempt + 2) # 4s, 8s, 16s
                    print(f"Rate limited (429) on {current_model}. Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                    last_error = "Rate Limit Exceeded (429)"
                    continue
                
                if response.status_code == 403:
                    last_error = f"API key rejected (403) for {current_model}"
                    print(f"API key rejected for {current_model}. Trying next model...")
                    continue
                
                if response.status_code == 404:
                    last_error = f"Model {current_model} not found (404)"
                    print(f"Model {current_model} not found. Trying next...")
                    continue
                
                response.raise_for_status()
                raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
                return _extract_json(raw)
                
            except requests.exceptions.HTTPError:
                last_error = f"HTTP error for {current_model}"
                continue
            except Exception as e:
                last_error = str(e)
                raise e

    except Exception as e:
        import traceback
        error_msg = str(e)
        if "429" in error_msg or "Rate Limit" in last_error:
            display_error = "Rate Limit Reached"
            explanation = "Your Gemini API Key has reached its quota limit (429). Please wait a few minutes or check your AI Studio usage."
        elif "404" in error_msg:
            display_error = "Model Not Found"
            explanation = f"The model '{MODEL_NAME}' returned a 404. Identifier might be region-locked."
        else:
            display_error = "Analysis Failed"
            explanation = f"Cloud AI returned an error: {error_msg}"

        with open("gemini_debug.log", "w") as f:
            f.write(f"Last Error: {last_error}\nTrace: {traceback.format_exc()}")
            
        print(f"Gemini Analysis Error: {last_error}")
        
        return {
            "crop": "Unknown",
            "predicted_disease": display_error,
            "confidence": 0.0,
            "explainability": {"method": "Error", "summary": last_error},
            "llm": {
                "disease_overview": explanation,
                "why_this_prediction": "Cloud AI service unavailable.",
                "chemical_treatments": [],
                "organic_treatments": [],
                "prevention_tips": ["Please check your internet and API quota."]
            }
        }


def _validate_ml_output(ml_output: dict):
    required = ["crop", "predicted_disease", "confidence", "explainability"]
    for k in required:
        if k not in ml_output:
            raise ValueError(f"Missing field: {k}")

    if ml_output["confidence"] < MIN_CONFIDENCE:
        raise ValueError("Confidence too low for LLM reasoning")

    for k in ["method", "summary"]:
        if k not in ml_output["explainability"]:
            raise ValueError(f"Missing explainability field: {k}")


def _extract_json(text: str) -> dict:
    text = text.strip()

    if text.startswith("```"):
        text = text.split("```")[1]

    start = text.find("{")
    end = text.rfind("}")

    if start == -1 or end == -1:
        raise RuntimeError(f"LLM did not return JSON:\n{text}")

    json_text = text[int(start) : int(end) + 1]  # type: ignore
    return json.loads(json_text)


def get_llm_explanation(ml_output: dict) -> dict:
    _validate_ml_output(ml_output)

    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY not set. Returning local explanation.")
        return _generate_local_explanation(ml_output)

    prompt = f"""
You are an agricultural plant pathology explanation system.

RULES:
- Do NOT invent diseases
- Use ONLY the AI output
- Reference Grad-CAM summary

AI OUTPUT:
{json.dumps(ml_output, indent=2)}

Return STRICT JSON with:
disease_overview
why_this_prediction
chemical_treatments
organic_treatments
prevention_tips
"""

    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    # Try each model in fallback chain
    for model_name in GEMINI_MODELS:
        url = f"{API_BASE}/{model_name}:generateContent"
        try:
            response = requests.post(
                f"{url}?key={GEMINI_API_KEY}",
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload),
                timeout=60
            )

            if response.status_code in (403, 404):
                print(f"LLM: {model_name} returned {response.status_code}, trying next model...")
                continue

            if response.status_code == 429:
                print(f"LLM: {model_name} rate limited, trying next model...")
                continue

            response.raise_for_status()
            raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            return _extract_json(raw)
        
        except Exception as e:
            print(f"LLM API Error ({model_name}): {e}")
            continue

    # All models failed — return local explanation
    print("All Gemini models failed. Returning local explanation.")
    return _generate_local_explanation(ml_output)


# --- LOCAL KNOWLEDGE BASE (No API needed) ---
_DISEASE_DB = {
    "Apple___Apple_scab": {
        "overview": "Apple Scab is a fungal disease caused by Venturia inaequalis. It produces olive-green to dark brown spots on leaves and fruit, leading to defoliation and reduced fruit quality.",
        "chemical": ["Mancozeb (fungicide spray)", "Captan 50% WP", "Myclobutanil"],
        "organic": ["Neem oil spray", "Sulfur-based fungicide", "Remove and destroy fallen leaves"],
        "prevention": ["Plant resistant apple varieties", "Ensure good air circulation in orchard", "Apply preventive sprays before rainy season", "Remove infected debris after harvest"]
    },
    "Apple___Black_rot": {
        "overview": "Black Rot is caused by the fungus Botryosphaeria obtusa. It causes circular brown lesions on leaves, rotting of fruit, and cankers on branches.",
        "chemical": ["Thiophanate-methyl", "Captan spray", "Mancozeb"],
        "organic": ["Prune infected branches", "Remove mummified fruits", "Apply copper-based fungicide"],
        "prevention": ["Remove dead wood and mummies from trees", "Maintain proper tree hygiene", "Avoid wounds on tree bark"]
    },
    "Apple___Cedar_apple_rust": {
        "overview": "Cedar Apple Rust is caused by Gymnosporangium juniperi-virginianae. It creates bright orange-yellow spots on apple leaves and requires both apple and cedar/juniper trees to complete its lifecycle.",
        "chemical": ["Myclobutanil", "Triadimefon", "Mancozeb"],
        "organic": ["Remove nearby juniper/cedar trees if possible", "Apply sulfur spray preventively"],
        "prevention": ["Plant rust-resistant apple varieties", "Remove galls from cedar trees in winter", "Apply fungicide at pink bud stage"]
    },
    "Tomato___Early_blight": {
        "overview": "Early Blight is caused by Alternaria solani. It produces dark brown spots with concentric rings (target-like) on lower leaves first, then spreads upward.",
        "chemical": ["Chlorothalonil", "Mancozeb", "Azoxystrobin"],
        "organic": ["Neem oil spray", "Copper fungicide", "Baking soda spray (1 tbsp per gallon)"],
        "prevention": ["Rotate crops (3 year cycle)", "Mulch around plants", "Water at base, avoid wetting leaves", "Remove infected lower leaves"]
    },
    "Tomato___Late_blight": {
        "overview": "Late Blight is caused by Phytophthora infestans. It causes dark, water-soaked lesions on leaves and stems, and white mold on undersides. Can destroy entire crop rapidly.",
        "chemical": ["Metalaxyl + Mancozeb", "Chlorothalonil", "Cymoxanil"],
        "organic": ["Copper hydroxide spray", "Remove and destroy infected plants immediately"],
        "prevention": ["Use certified disease-free seeds", "Avoid overhead irrigation", "Ensure good air circulation", "Monitor weather for humid conditions"]
    },
    "Tomato___Bacterial_spot": {
        "overview": "Bacterial Spot is caused by Xanthomonas species. It creates small, dark, water-soaked spots on leaves, stems, and fruit.",
        "chemical": ["Copper-based bactericide", "Streptomycin sulfate"],
        "organic": ["Copper hydroxide spray", "Remove infected plant debris"],
        "prevention": ["Use disease-free seeds and transplants", "Avoid working with wet plants", "Rotate crops", "Disinfect tools"]
    },
    "Tomato___Leaf_Mold": {
        "overview": "Leaf Mold is caused by Passalora fulva. Yellow spots appear on upper leaf surfaces with olive-green mold on undersides, common in humid greenhouse conditions.",
        "chemical": ["Chlorothalonil", "Mancozeb"],
        "organic": ["Improve ventilation", "Neem oil", "Remove infected leaves"],
        "prevention": ["Increase air circulation", "Reduce humidity", "Space plants properly", "Use resistant varieties"]
    },
    "Tomato___Septoria_leaf_spot": {
        "overview": "Septoria Leaf Spot is caused by Septoria lycopersici. Small circular spots with dark borders and gray centers appear on lower leaves.",
        "chemical": ["Chlorothalonil", "Mancozeb", "Copper fungicide"],
        "organic": ["Remove infected leaves", "Neem oil spray", "Mulching"],
        "prevention": ["Crop rotation", "Avoid overhead watering", "Stake plants for air circulation"]
    },
    "Tomato___Target_Spot": {
        "overview": "Target Spot is caused by Corynespora cassiicola. It creates concentric ringed spots on leaves, similar to early blight but with different ring patterns.",
        "chemical": ["Azoxystrobin", "Difenoconazole", "Chlorothalonil"],
        "organic": ["Neem oil", "Remove and destroy infected plant parts"],
        "prevention": ["Proper spacing between plants", "Avoid excess nitrogen fertilization", "Crop rotation"]
    },
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": {
        "overview": "TYLCV is a viral disease transmitted by whiteflies. Leaves curl upward, turn yellow, and plants become stunted with significantly reduced fruit production.",
        "chemical": ["Imidacloprid (for whitefly control)", "Thiamethoxam"],
        "organic": ["Yellow sticky traps for whiteflies", "Neem oil spray", "Remove infected plants"],
        "prevention": ["Use TYLCV-resistant varieties", "Control whitefly populations", "Use reflective mulch", "Remove weeds that harbor whiteflies"]
    },
    "Tomato___Tomato_mosaic_virus": {
        "overview": "Tomato Mosaic Virus (ToMV) causes mottled light and dark green patterns on leaves, leaf curling, and stunted growth. Spread by contact.",
        "chemical": ["No chemical cure for viruses"],
        "organic": ["Remove and destroy infected plants", "Disinfect hands and tools with milk solution"],
        "prevention": ["Use resistant varieties", "Disinfect all tools", "Wash hands before handling plants", "Do not smoke near plants (tobacco mosaic cross-infection)"]
    },
    "Tomato___Spider_mites Two-spotted_spider_mite": {
        "overview": "Two-spotted spider mites are tiny arachnids that suck plant sap, causing stippled, yellowed leaves with fine webbing on undersides.",
        "chemical": ["Abamectin", "Bifenthrin", "Spiromesifen"],
        "organic": ["Strong water spray to dislodge mites", "Neem oil", "Introduce predatory mites (Phytoseiulus persimilis)"],
        "prevention": ["Keep plants well-watered (stressed plants attract mites)", "Avoid dusty conditions", "Monitor regularly with hand lens"]
    },
    "Potato___Early_blight": {
        "overview": "Potato Early Blight is caused by Alternaria solani. It creates dark brown concentric ringed spots on older leaves, reducing tuber yield.",
        "chemical": ["Mancozeb", "Chlorothalonil", "Azoxystrobin"],
        "organic": ["Copper fungicide", "Neem oil spray"],
        "prevention": ["Use certified seed potatoes", "Crop rotation (3+ years)", "Adequate fertilization", "Remove infected foliage"]
    },
    "Potato___Late_blight": {
        "overview": "Potato Late Blight is caused by Phytophthora infestans (the disease that caused the Irish Potato Famine). It causes dark, water-soaked lesions that spread rapidly.",
        "chemical": ["Metalaxyl + Mancozeb", "Cymoxanil", "Chlorothalonil"],
        "organic": ["Copper-based spray", "Destroy all infected plants"],
        "prevention": ["Plant resistant varieties", "Use certified disease-free seed potatoes", "Hill soil around plants", "Harvest in dry weather"]
    },
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": {
        "overview": "Gray Leaf Spot is caused by Cercospora zeae-maydis. It creates rectangular gray-brown lesions between leaf veins, reducing photosynthesis and yield.",
        "chemical": ["Azoxystrobin", "Pyraclostrobin", "Propiconazole"],
        "organic": ["Crop rotation with non-host crops", "Tillage to bury infected residue"],
        "prevention": ["Plant resistant hybrids", "Rotate with soybeans or small grains", "Reduce plant density for better air flow"]
    },
    "Corn_(maize)___Common_rust_": {
        "overview": "Common Rust is caused by Puccinia sorghi. Small, circular to elongated reddish-brown pustules appear on both leaf surfaces.",
        "chemical": ["Propiconazole", "Azoxystrobin", "Mancozeb"],
        "organic": ["Plant early to avoid peak rust period"],
        "prevention": ["Use rust-resistant hybrids", "Plant early in the season", "Monitor fields when temperatures are 60-77°F with high humidity"]
    },
    "Corn_(maize)___Northern_Leaf_Blight": {
        "overview": "Northern Leaf Blight is caused by Exserohilum turcicum. Long, elliptical gray-green lesions appear on leaves, potentially causing significant yield loss.",
        "chemical": ["Azoxystrobin", "Propiconazole", "Pyraclostrobin"],
        "organic": ["Crop rotation", "Bury crop residue"],
        "prevention": ["Plant resistant hybrids", "Rotate crops", "Reduce plant stress with proper nutrition"]
    },
    "Grape___Black_rot": {
        "overview": "Grape Black Rot is caused by Guignardia bidwellii. It causes brown leaf spots and shriveled, black 'mummified' berries.",
        "chemical": ["Myclobutanil", "Mancozeb", "Captan"],
        "organic": ["Remove mummified berries", "Prune for air circulation"],
        "prevention": ["Remove all mummies and infected canes", "Apply fungicides from bud break to veraison", "Maintain good canopy management"]
    },
    "Grape___Esca_(Black_Measles)": {
        "overview": "Esca (Black Measles) is a complex trunk disease caused by multiple fungi. It causes tiger-stripe patterns on leaves and dark spots on berries.",
        "chemical": ["No fully effective chemical treatment"],
        "organic": ["Trunk surgery to remove infected wood", "Apply wound sealant after pruning"],
        "prevention": ["Prune in late season to reduce infection risk", "Use clean pruning tools", "Avoid large pruning wounds"]
    },
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": {
        "overview": "Grape Leaf Blight (Isariopsis) causes angular, brown spots on leaves with dark borders, potentially leading to premature defoliation.",
        "chemical": ["Mancozeb", "Copper oxychloride"],
        "organic": ["Neem oil spray", "Remove fallen leaves"],
        "prevention": ["Good air circulation through pruning", "Avoid overhead irrigation", "Apply preventive fungicides"]
    },
    "Peach___Bacterial_spot": {
        "overview": "Bacterial Spot of Peach is caused by Xanthomonas arboricola. It creates small, dark, angular spots on leaves and sunken spots on fruit.",
        "chemical": ["Copper hydroxide (dormant spray)", "Oxytetracycline"],
        "organic": ["Copper-based sprays during dormancy", "Remove infected twigs"],
        "prevention": ["Plant resistant varieties", "Avoid working with wet plants", "Provide good air drainage"]
    },
    "Pepper,_bell___Bacterial_spot": {
        "overview": "Bacterial Spot of Pepper is caused by Xanthomonas species. It causes small, dark, raised spots on leaves and fruit, reducing quality and yield.",
        "chemical": ["Copper hydroxide + Mancozeb", "Streptomycin"],
        "organic": ["Copper-based spray", "Remove infected plant material"],
        "prevention": ["Use disease-free seeds", "Hot water seed treatment", "Crop rotation", "Avoid overhead watering"]
    },
    "Strawberry___Leaf_scorch": {
        "overview": "Strawberry Leaf Scorch is caused by Diplocarpon earlianum. It creates irregular dark purple spots that merge, giving leaves a scorched appearance.",
        "chemical": ["Captan", "Thiram"],
        "organic": ["Remove infected leaves", "Apply compost tea"],
        "prevention": ["Plant resistant varieties", "Renovate beds after harvest", "Improve drainage and air circulation"]
    },
    "Squash___Powdery_mildew": {
        "overview": "Powdery Mildew on squash is caused by Podosphaera xanthii. White powdery coating appears on leaf surfaces, reducing photosynthesis.",
        "chemical": ["Myclobutanil", "Sulfur", "Triadimefon"],
        "organic": ["Milk spray (1:9 milk:water)", "Potassium bicarbonate", "Neem oil"],
        "prevention": ["Plant resistant varieties", "Space plants widely", "Water at soil level", "Remove infected leaves promptly"]
    },
    "Cherry_(including_sour)___Powdery_mildew": {
        "overview": "Powdery Mildew on cherry creates white, powdery patches on leaves and new shoots. It can distort new growth and reduce fruit quality.",
        "chemical": ["Myclobutanil", "Sulfur spray", "Trifloxystrobin"],
        "organic": ["Neem oil", "Potassium bicarbonate solution"],
        "prevention": ["Prune for air circulation", "Avoid excess nitrogen", "Apply preventive fungicide at petal fall"]
    },
    "Orange___Haunglongbing_(Citrus_greening)": {
        "overview": "Citrus Greening (HLB) is a devastating bacterial disease spread by Asian citrus psyllid. It causes yellow shoots, lopsided bitter fruit, and eventual tree death.",
        "chemical": ["Imidacloprid (for psyllid control)", "Neonicotinoids"],
        "organic": ["Release natural predators of psyllid (Tamarixia radiata)", "Remove infected trees promptly"],
        "prevention": ["Use certified disease-free nursery stock", "Control psyllid populations", "Report suspected infections to authorities", "Regular scouting"]
    },
}


def _generate_local_explanation(ml_output: dict) -> dict:
    """Generate explanation from local knowledge base (no API needed)."""
    disease = ml_output.get("predicted_disease", "Unknown")
    crop = ml_output.get("crop", "Unknown")
    confidence = ml_output.get("confidence", 0.0)
    
    # Check if it's healthy
    if "healthy" in disease.lower():
        return {
            "disease_overview": f"Your {crop} plant appears healthy! No signs of disease were detected by the AI analysis.",
            "why_this_prediction": f"The AI model analyzed the leaf patterns with {confidence*100:.1f}% confidence and found no indicators of disease. The plant shows normal coloration and structure.",
            "chemical_treatments": [],
            "organic_treatments": ["Continue regular care", "Monitor for any changes"],
            "prevention_tips": [
                "Maintain proper watering schedule",
                "Ensure adequate sunlight and spacing",
                "Use balanced fertilizers",
                "Regular weeding and pest monitoring"
            ]
        }

    # Look up in disease database
    if disease in _DISEASE_DB:
        info = _DISEASE_DB[disease]
        readable_disease = disease.replace("___", " - ").replace("_", " ")
        return {
            "disease_overview": info["overview"],
            "why_this_prediction": f"The AI model detected visual patterns with {confidence*100:.1f}% confidence that are consistent with {readable_disease}. Analysis based on leaf coloration, lesion patterns, and texture features.",
            "chemical_treatments": info["chemical"],
            "organic_treatments": info["organic"],
            "prevention_tips": info["prevention"]
        }
    
    # Generic fallback for unknown diseases
    readable_disease = disease.replace("___", " - ").replace("_", " ")
    return {
        "disease_overview": f"The AI detected {readable_disease} on your {crop} plant. This condition was identified with {confidence*100:.1f}% confidence based on visual analysis.",
        "why_this_prediction": f"Pattern analysis revealed visual features consistent with {readable_disease} including leaf discoloration and textural changes.",
        "chemical_treatments": ["Consult your local agricultural extension officer for specific treatment recommendations"],
        "organic_treatments": ["Neem oil spray", "Remove and destroy affected leaves", "Improve air circulation around plants"],
        "prevention_tips": [
            "Practice crop rotation",
            "Use disease-resistant varieties",
            "Maintain proper plant spacing",
            "Avoid overhead watering",
            "Remove plant debris after harvest"
        ]
    }
