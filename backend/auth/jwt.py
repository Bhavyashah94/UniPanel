from jose import jwt
from datetime import datetime, timedelta

SECRET_KEY = "supersecret"
ALGORITHM = "HS256"

def create_token(user_data):
    payload = {
        "sub": user_data["google_id"],
        "name": user_data["name"],
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
