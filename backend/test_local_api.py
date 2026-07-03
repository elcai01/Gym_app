import urllib.request
import json

def main():
    for port in [8000, 8001, 8080, 5000]:
        try:
            url = f"http://localhost:{port}/rutinas/"
            print(f"Trying: {url}")
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=2) as response:
                data = json.loads(response.read().decode())
                print(f"SUCCESS on port {port}. Total routines: {len(data)}")
                for r in data[:5]:
                    print(f" - {r.get('id')}: {r.get('nombre')}")
                return
        except Exception as e:
            print(f"Failed on port {port}: {e}")

if __name__ == "__main__":
    main()
