
import os
import sys
import os
import sys
from dotenv import load_dotenv

# Load env from .env file in current directory
load_dotenv()

from doc_feature.llm import analyze_image_with_gemini

# Ensure we can import from doc_feature
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

TEST_IMAGE_PATH = os.path.join("doc_feature", "test_image.jpg")

if not os.path.exists(TEST_IMAGE_PATH):
    print(f"Error: Test image not found at {TEST_IMAGE_PATH}")
    sys.exit(1)

print(f"Testing Gemini Vision with model: gemini-1.5-flash")
print(f"Using image: {TEST_IMAGE_PATH}")

try:
    result = analyze_image_with_gemini(TEST_IMAGE_PATH)
    print("\n--- Success! ---")
    print(f"Crop: {result.get('crop')}")
    print(f"Disease: {result.get('predicted_disease')}")
    print(f"Confidence: {result.get('confidence')}")
except Exception as e:
    print(f"\n--- Failed ---")
    print(f"Error: {e}")
