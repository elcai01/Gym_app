import urllib.request
import json

def get_url(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode())

def main():
    try:
        # 1. Get current routine for client 693
        url = "https://api.gymstylelifeco.com/rutinas/cliente/693/actual"
        print(f"Fetching: {url}")
        data = get_url(url)
        print(json.dumps(data, indent=2))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
