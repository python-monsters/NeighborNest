
import requests
from fastapi import Request
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from typing import Optional, List
import mysql.connector
import os
import stripe
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Enable CORS for all origins
origins = ["*"]
app.add_middleware(CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# JWT auth setup
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
SECRET_KEY = os.getenv("JWT_SECRET", "secret")
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
stripe.api_key = STRIPE_SECRET_KEY

# Pydantic models
class User(BaseModel):
    email: str
    password: str

class Listing(BaseModel):
    user_id: int
    title: str
    price: float
    is_auction: Optional[bool] = False
    weight: Optional[float] = 0.0
    image_url: Optional[str] = ""

class Bid(BaseModel):
    listing_id: int
    user_id: int
    amount: float

# --- Auth Endpoints ---

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

# --- Listings CRUD ---

@app.post("/listings")
def create_listing(listing: Listing):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO listings (user_id, title, price, is_auction, weight, image_url) VALUES (%s, %s, %s, %s, %s, %s)",
                   (listing.user_id, listing.title, listing.price, listing.is_auction, listing.weight, listing.image_url))
    db.commit()
    return {"message": "Listing created"}

@app.get("/listings")
def get_listings():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM listings")
    listings = cursor.fetchall()
    return listings

@app.put("/listings/{listing_id}")
def update_listing(listing_id: int, listing: Listing):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("UPDATE listings SET title=%s, price=%s, is_auction=%s, weight=%s, image_url=%s WHERE id=%s",
                   (listing.title, listing.price, listing.is_auction, listing.weight, listing.image_url, listing_id))
    db.commit()
    return {"message": "Listing updated"}

@app.delete("/listings/{listing_id}")
def delete_listing(listing_id: int):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM listings WHERE id=%s", (listing_id,))
    db.commit()
    return {"message": "Listing deleted"}

# --- Bids ---

@app.post("/bids")
def create_bid(bid: Bid):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("INSERT INTO bids (listing_id, user_id, amount) VALUES (%s, %s, %s)",
                   (bid.listing_id, bid.user_id, bid.amount))
    db.commit()
    return {"message": "Bid placed"}

@app.get("/bids/{listing_id}")
def get_bids_for_listing(listing_id: int):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM bids WHERE listing_id = %s ORDER BY amount DESC", (listing_id,))
    bids = cursor.fetchall()
    return bids

# --- Stripe Webhook ---

@app.post("/webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
        if event["type"] == "checkout.session.completed":
            data = event["data"]["object"]
            db = get_db()
            cursor = db.cursor()
            cursor.execute("INSERT INTO payments (user_id, listing_id, amount, status) VALUES (%s, %s, %s, %s)",
                           (1, 1, data["amount_total"] / 100, "succeeded"))  # replace with real IDs
            db.commit()
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    return {"received": True}
#------create checkout session-----
@app.post("/create-checkout-session")
def create_checkout_session():
    session = stripe.checkout.Session.create(
        payment_method_types=['card'],
        line_items=[{
            'price_data': {
                'currency': 'usd',
                'product_data': {'name': 'Auction Item'},
                'unit_amount': 5000,  # $50.00
            },
            'quantity': 1,
        }],
        mode='payment',
        success_url='https://your-app.com/success',
        cancel_url='https://your-app.com/cancel',
    )
    return {"id": session.id, "url": session.url}

#0-----Calculate Shipping Cost------
@app.get("/calculate-shipping")
def calculate_shipping(weight_oz: float, origin_zip: str, dest_zip: str):
    USPS_USER_ID = os.getenv("USPS_USER_ID")
    url = "http://production.shippingapis.com/ShippingAPI.dll"
    xml_payload = f"""<RateV4Request USERID='{USPS_USER_ID}'>
        <Revision>2</Revision>
        <Package ID='1ST'>
            <Service>PRIORITY</Service>
            <ZipOrigination>{origin_zip}</ZipOrigination>
            <ZipDestination>{dest_zip}</ZipDestination>
            <Pounds>0</Pounds>
            <Ounces>{weight_oz}</Ounces>
            <Container/>
            <Size>REGULAR</Size>
            <Machinable>true</Machinable>
        </Package>
    </RateV4Request>"""
    payload = {"API": "RateV4", "XML": xml_payload}
    response = requests.get(url, params=payload)
    return response.text


# --- Utilities ---

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

def initialize_database():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
    CREATE DATABASE IF NOT EXISTS neighbornest;
    USE neighbornest;

    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS listings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        title VARCHAR(255),
        price DECIMAL(10,2),
        is_auction BOOLEAN DEFAULT FALSE,
        weight DECIMAL(10,2),
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        listing_id INT,
        user_id INT,
        amount DECIMAL(10,2),
        bid_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS payments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        listing_id INT,
        amount DECIMAL(10,2),
        status VARCHAR(50),
        payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (listing_id) REFERENCES listings(id)
    );
    """)
    db.commit()
    cursor.close()
    db.close()

# Run this when app starts
initialize_database()

