import requests
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
data = {
    "contents": [{
        "parts":[{"text": "Hello, are you working?"}]
    }]
}
response = requests.post(url, json=data)
print(response.json())
