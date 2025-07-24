from google.oauth2 import id_token
from google.auth.transport import requests
from fastapi import HTTPException

import os


GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")

def verify_google_token(id_token_str: str):
    try:
        idinfo = id_token.verify_oauth2_token(
            id_token_str,
            requests.Request(),
            GOOGLE_CLIENT_ID
        )

        print("Token verified successfully.")
        print("ID Info:", idinfo)

        user_mail = idinfo.get("email")
        user_mail_domain = user_mail.split('@')[1]
        if(user_mail_domain!="atharvacoe.ac.in"):
            raise HTTPException(status_code=401, detail="not from college")

        return {
            "google_id": idinfo["sub"],
            "email": idinfo.get("email"),
            "name": idinfo.get("name", "")
        }

    except ValueError as e:
        print("Token verification failed:", str(e))
        raise HTTPException(status_code=403, detail="Invalid token")

