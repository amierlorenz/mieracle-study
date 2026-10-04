"""PROTOTYPE — throwaway. Shared Gemini call with 503/429 retry and Flash fallback.

Key: $GEMINI_API_KEY, else the login-keychain item `mieracle-gemini-prototype`.
"""
import json, os, subprocess, sys, time, urllib.error, urllib.request

key = os.environ.get("GEMINI_API_KEY") or subprocess.run(
    ["security", "find-generic-password", "-s", "mieracle-gemini-prototype", "-w"], capture_output=True, text=True).stdout.strip()


def generate(models, system, parts, schema):
    body = {
        "systemInstruction": {"parts": [{"text": system}]},
        "contents": [{"role": "user", "parts": parts}],
        "generationConfig": {"responseMimeType": "application/json", "responseJsonSchema": schema},
    }
    attempts = []
    start = time.time()
    for m in models:
        for wait in [0, 15, 45]:
            time.sleep(wait)
            req = urllib.request.Request(
                f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent",
                data=json.dumps(body).encode(),
                headers={"Content-Type": "application/json", "x-goog-api-key": key},
            )
            try:
                raw = json.load(urllib.request.urlopen(req, timeout=600))
                result = json.loads(raw["candidates"][0]["content"]["parts"][0]["text"])
                return result, {"model": m, "seconds": round(time.time() - start), "usage": raw.get("usageMetadata"), "failed_attempts": attempts}
            except urllib.error.HTTPError as e:
                attempts.append(f"{m}: HTTP {e.code}")
                print(f"{m}: HTTP {e.code} {e.read().decode(errors='replace')[:200]}", file=sys.stderr)
                if e.code not in (429, 500, 503):
                    sys.exit(1)
    sys.exit("gemini: every model failed: " + ", ".join(attempts))
