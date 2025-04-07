
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from typing import Optional
import mysql.connector
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

origins = ["*"]
app.add_middleware(CORSMiddleware, allow_origins=origins,
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
SECRET_KEY = os.getenv("JWT_SECRET", "secret")

class User(BaseModel):
    email: str
    password: str

@app.post("/signup")
def signup(user: User):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO users (email, password) VALUES (%s, %s)", (user.email, user.password))
    db.commit()
    return {"message": "User created"}

@app.post("/token")
def login(user: User):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE email = %s AND password = %s", (user.email, user.password))
    result = cursor.fetchone()
    if result:
        token = jwt.encode({"sub": user.email}, SECRET_KEY, algorithm="HS256")
        return {"access_token": token, "token_type": "bearer"}
    raise HTTPException(status_code=401, detail="Invalid credentials")

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database="neighbornest"
    )

@app.get("/")
def root():
    return {"message": "NeighborNest API is running"}
