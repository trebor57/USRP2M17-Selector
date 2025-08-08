# -*- coding: utf-8 -*-
from __future__ import print_function, unicode_literals
import json, unicodedata, requests, re, io

URL = "https://hostfiles.refcheck.radio/M17Hosts.json"
OUTPUT = "reflector_options.txt"

def _norm(s):
    if not s: return u""
    return unicodedata.normalize("NFKC", s).replace(u"\u00a0", u" ").strip()

def norm_designator(d):
    import re
    d = _norm(d).upper()
    if not d:
        return u"M17-???"
    m = re.match(r'^(?:M17[-\s]?)([A-Z0-9]+)$', d)
    if m:
        return u"M17-" + m.group(1)
    if re.match(r'^[A-Z0-9]+$', d):
        return u"M17-" + d
    return d

def pick_display(entry):
    for k in ("name", "sponsor", "slug"):
        v = _norm(entry.get(k))
        if v: return v
    return entry.get("designator", u"UNKNOWN")

def pick_ip(entry):
    return entry.get("ipv4") or entry.get("ipv6") or u"unknown"

def pick_url(entry):
    return entry.get("url") or u"N/A"

def build_lines(reflectors):
    lines = []
    reflectors = sorted(reflectors, key=lambda r: _norm(r.get("designator")))
    for r in reflectors:
        designator = norm_designator(r.get("designator"))
        display    = pick_display(r)
        ip         = pick_ip(r)
        country    = r.get("country") or u"??"
        url        = pick_url(r)
        lines.append(u"{} - {} ({}) - Country: {} - URL: {}".format(
            designator, display, ip, country, url
        ))
    return lines

def main():
    print("Downloading latest M17Hosts.json...")
    r = requests.get(URL, timeout=30, headers={"User-Agent": "curl/8"})
    r.raise_for_status()
    data = r.json()
    lines = build_lines(data.get("reflectors", []))
    # io.open with encoding works in both Py2 and Py3
    with io.open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(u"\n".join(lines))
    print("Wrote {}".format(OUTPUT))

if __name__ == "__main__":
    main()
