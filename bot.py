#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.feedparser python3Packages.requests2 python3Packages.beautifulsoup4

import pprint
import contextlib
import bs4
import functools
import feedparser
import os
import requests
import time


CONTENT = "@everyone New TF2 Blog Post"
TF2_RSS = "http://www.teamfortress.com/rss.xml"
COLOR = 11751957

os.environ["TZ"] = "Europe/Paris"
time.tzset()

with open("last_update") as last_update_file:
    last_update = float(last_update_file.read())

rss = feedparser.parse(TF2_RSS, modified=time.localtime(last_update))

if rss.status == 304:
    exit()

cached_soup = functools.lru_cache()(bs4.BeautifulSoup)

def get_image(summary):
    with contextlib.suppress(TypeError):
        return cached_soup(summary, "html.parser").img["src"]

payload = {
        "content": CONTENT,
        "embeds": [
            {
                "title": entry["title"],
                "description": cached_soup(entry["summary"], "html.parser").get_text()[:2000],
                "url": entry["id"],
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", entry["published_parsed"]),
                "color": COLOR,
                "image": { "url": get_image(entry["summary"]) },
            }
            for entry in rss["entries"]
            if time.mktime(entry["published_parsed"]) > last_update
        ]
    }

with open("webhooks") as webhooks:
    for webhook in webhooks:
        response = requests.post(webhook[:-1], json=payload)
        if response.status_code >= 300:
            print("Webhook failed ({r.status_code}: {r.reason}) {r.text} {r.url}".format(r=response))
            pprint.pprint(payload)
        time.sleep(1)

latest_update = time.mktime(rss["updated_parsed"])

with open("last_update", "w") as last_update:
    last_update.write(str(latest_update))
