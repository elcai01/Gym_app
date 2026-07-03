import urllib.request

def main():
    try:
        url = "https://api.gymstylelifeco.com/"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            print("Headers:")
            for k, v in response.info().items():
                print(f" {k}: {v}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
