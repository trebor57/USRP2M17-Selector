import requests
import json

API_URL = "https://dvref.com/mrefd/reflectors/?include_description=true"
RAW_OUTPUT = "raw_reflectors.json"
OUTPUT = "reflector_options.txt"

def update_reflector_file(reflectors):
    with open(OUTPUT, "w", encoding="utf-8") as f:
        for r in reflectors:
            # Build name: Prefer 'name', fall back to 'sponsor'
            display_name = r.get('name') or r.get('sponsor') or ''
            designator = r.get('designator', '')
            country = r.get('country', 'N/A')
            ip = r.get('ipv4') or r.get('ipv6') or 'N/A'
            url = r.get('url', '(none)')
            if designator and ip:
                line = f"M17-{designator} - {display_name} ({ip}) - Country: {country} - URL: {url}\n"
                f.write(line)

def main():
    headers = {'User-Agent': 'Mozilla/5.0'}
    resp = requests.get(API_URL, headers=headers)
    resp.raise_for_status()
    # Save raw JSON for inspection
    with open(RAW_OUTPUT, "w", encoding="utf-8") as rawfile:
        rawfile.write(resp.text)
    print(f"Saved raw JSON to {RAW_OUTPUT}")

    data = resp.json()
    reflectors = data.get('reflectors', [])
    update_reflector_file(reflectors)
    print("Reflector options updated from API!")

if __name__ == "__main__":
    main()
