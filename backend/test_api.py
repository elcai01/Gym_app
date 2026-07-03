import urllib.request
import json

def main():
    try:
        url = "https://api.gymstylelifeco.com/rutinas/"
        print(f"Fetching from: {url}")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            print(f"Total routines found: {len(data)}")
            print("First few routines:")
            for r in data[:10]:
                print(f" - {r.get('id')}: {r.get('nombre')}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
