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

MODEL_NAME = "gemini-flash-lite-latest"  # Usually maps to 1.5 Flash Lite, stable
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL_NAME}:generateContent"
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

        # RETRY LOGIC for 429 Errors
        max_retries = 3
        last_error = "Unknown Error"
        
        for attempt in range(max_retries):
            try:
                response = requests.post(
                    f"{API_URL}?key={GEMINI_API_KEY}",
                    headers={"Content-Type": "application/json"},
                    data=json.dumps(payload),
                    timeout=30 # Reduced timeout
                )
                
                if response.status_code == 429:
                    wait_time = 2 ** (attempt + 2) # 4s, 8s, 16s
                    print(f"Rate limited (429). Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                    last_error = "Rate Limit Exceeded (429)"
                    continue
                
                response.raise_for_status()
                raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
                return _extract_json(raw)
                
            except Exception as e:
                last_error = str(e)
                if isinstance(e, requests.exceptions.HTTPError) and response.status_code == 429:
                    continue # Handled above
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
        print("GEMINI_API_KEY not set. Returning mock explanation.")
        return {
            "disease_overview": f"This is a simulated explanation for {ml_output.get('predicted_disease', 'unknown disease')}.",
            "why_this_prediction": "The AI model detected patterns consistent with this disease based on leaf coloration and lesions.",
            "chemical_treatments": ["Mock Chemical A", "Mock Chemical B"],
            "organic_treatments": ["Neem Oil", "Copper Fungicide"],
            "prevention_tips": ["Ensure proper spacing", "Avoid overhead watering"]
        }

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

    try:
        response = requests.post(
            f"{API_URL}?key={GEMINI_API_KEY}",
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload),
            timeout=60
        )

        response.raise_for_status()
        raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        return _extract_json(raw)
    
    except Exception as e:
        print(f"LLM API Error: {e}. Returning mock data.")
        return {
            "disease_overview": f"This is a simulated explanation for {ml_output.get('predicted_disease', 'unknown disease')} (API Error).",
            "why_this_prediction": "The AI model detected patterns consistent with this disease based on leaf coloration and lesions.",
            "chemical_treatments": ["Mock Chemical A", "Mock Chemical B"],
            "organic_treatments": ["Neem Oil", "Copper Fungicide"],
            "prevention_tips": ["Ensure proper spacing", "Avoid overhead watering"]
        }
