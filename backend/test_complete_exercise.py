import urllib.request
import urllib.error
import json

def main():
    # We try to mark exercise 88 as cumplido for cliente_rutina 30
    url = "https://api.gymstylelifeco.com/rutinas/cliente-rutina/30/ejercicio/88/cumplir"
    print(f"POSTing to: {url}")
    req = urllib.request.Request(
        url, 
        data=b"",  # Empty body POST
        headers={'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json'}
    )
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            print("SUCCESS:")
            print(json.dumps(data, indent=2))
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.reason}")
        print(e.read().decode())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
