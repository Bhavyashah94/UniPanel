from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from auth.google_auth import verify_google_token
from auth.jwt import create_token

app = FastAPI()

# CORS to allow frontend to talk to backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5500"],  # or wherever your frontend runs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/auth/google")
async def login(request: Request):
    body = await request.json()
    token = body.get("token")

    if not token:
        raise HTTPException(status_code=400, detail="No token provided")

    # Just remove the await here:
    user_data = verify_google_token(token)

    jwt_token = create_token(user_data)

    return {
        "token": jwt_token,
        "name": user_data["name"],
    }

