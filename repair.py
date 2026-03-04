import os
import requests
import json
import re

def ask_gemini_for_fix(log_tail):
    api_key = os.getenv("GEMINI_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    prompt_text = (
        f"The MicroPython ESP32-S3 build failed. Here are the last lines of the log:\n\n"
        f"{log_tail}\n\n"
        f"Provide a single bash command to fix this error. "
        f"Return ONLY the bash command inside a code block like this: ```bash ... ```"
    )
    
    payload = {"contents": [{"parts": [{"text": prompt_text}]}]}
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        data = response.json()
        raw_text = data['candidates'][0]['content']['parts'][0]['text']
        
        # Extract command from markdown code block
        match = re.search(r'
http://googleusercontent.com/immersive_entry_chip/0

---

### What happens now?
1. **Push your code**: As soon as you push these files, the Action starts.
2. **Failure happens**: If the `pkg_resources` error (or any other) occurs, the first build step marks a "failure" but continues.
3. **Gemini wakes up**: The `repair.py` script reads the log, talks to Gemini using your secret key, and executes the fix (like that `sed` patch or a `pip install`).
4. **Victory**: The "Final Build Attempt" runs on the now-repaired environment.

Would you like me to show you how to add a **Slack or Discord notification** so Gemini can message you when it successfully "heals" a build?
