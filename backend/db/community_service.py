# kvb/db/community_service.py
from .firebase_init import db
from firebase_admin import firestore
from datetime import datetime
try:
    from google.cloud.firestore import Increment, ArrayUnion
except Exception as e:
    print(f"Google Cloud Firestore types not available: {e}")
    # Mock classes if library is missing
    class Increment:
        def __init__(self, value): self.value = value
    class ArrayUnion:
        def __init__(self, values): self.values = values


# ---------------- CREATE POST ----------------
def create_post(user_id: str, content: str, lat: float, lng: float, image_url: str = None, analysis_data: dict = None, user_name: str = None) -> str:
    """
    Create a community post with normalized location.
    
    Args:
        user_id: User ID (phone number)
        content: Post content
        lat: Latitude
        lng: Longitude
        image_url: Optional URL to an uploaded image
        analysis_data: Optional analysis/diagnosis data dict
        user_name: Optional display name of the user
    
    Returns:
        Post document ID
    """
    # Import here to avoid circular dependency
    from location.location_service import normalize_location
    
    # Normalize location
    location = normalize_location(lat, lng)

    if db is None:
        return "mock_post_id"
    
    post_data = {
        "userId": user_id,
        "userName": user_name or "Farmer",
        "content": content,
        "location": location,
        "likes": 0,
        "commentsCount": 0,
        "createdAt": datetime.utcnow()
    }
    
    if image_url:
        post_data["imageUrl"] = image_url
    if analysis_data:
        post_data["analysisData"] = analysis_data
    
    doc_ref = db.collection("community").document()
    doc_ref.set(post_data)
    
    return doc_ref.id


# ---------------- GET FEED ----------------
def get_posts(limit: int = 20):
    """Get recent community posts."""
    if db is None:
        return []

    posts = (
        db.collection("community")
        .order_by("createdAt", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )
    posts_list = []
    for doc in posts:
        data = doc.to_dict()
        if "createdAt" in data and hasattr(data["createdAt"], "isoformat"):
            data["createdAt"] = data["createdAt"].isoformat()
        posts_list.append({"id": doc.id, **data})
    return posts_list


# ---------------- ADD COMMENT ----------------
def add_comment(post_id: str, user_id: str, content: str):
    """Add a comment to a post."""
    if db is None:
        return

    post_ref = db.collection("community").document(post_id)
    
    # Add comment as subcollection
    post_ref.collection("comments").add({
        "userId": user_id,
        "content": content,
        "createdAt": datetime.utcnow()
    })
    
    # Increment comment count
    post_ref.update({
        "commentsCount": Increment(1)
    })


# ---------------- LIKE POST ----------------
def like_post(post_id: str, user_id: str):
    """Like a post (increment count and track user)."""
    if db is None:
        return

    post_ref = db.collection("community").document(post_id)
    
    post_ref.update({
        "likes": Increment(1),
        "likedBy": ArrayUnion([user_id])
    })