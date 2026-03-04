import os
import requests
import json

def ask_gemini_for_fix(log_tail):
    api_key = os.getenv("GEMINI_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    prompt = {
        "contents": [{
            "parts": [{
                "text": f"The MicroPython ESP32-S3 build failed with this error:\n\n{log_tail}\n\n"
                        f"Provide a single bash command to fix this. "
                        f"Respond ONLY with the command, no explanation."
            }]
        }]
    }
    
    response = requests.post(url, json=prompt)
    result = response.json()
    return result['candidates'][0]['content']['parts'][0]['text'].strip()

if __name__ == "__main__":
    if os.path.exists("build_log.txt"):
        with open("build_log.txt", "r") as f:
            logs = f.readlines()[-50:] # Get last 50 lines
        
        fix_command = ask_gemini_for_fix("".join(logs))
        print(f"Gemini suggests: {fix_command}")
        
        # Execute the fix
        os.system(fix_command)
    else:
        print("No log file found to repair.")
