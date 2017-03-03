#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.feedparser python3Packages.requests2 python3Packages.beautifulsoup4 python3Packages.flask

import argparse
import bs4
import feedparser
from flask import Flask, request, render_template
import os
import random
import requests
import time


CONTENT = "New TF2 Blog Post"
TF2_RSS = "http://www.teamfortress.com/rss.xml"
BASE = "https://discordapp.com/api/webhooks/"
COLOR = 11751957

os.environ["TZ"] = "Europe/Paris"
time.tzset()

application = Flask(__name__)

@application.route('/', methods=["POST", "GET"])
def index():

    failed = False

    if request.method == "POST":
        webhook = "/".join(request.form["webhook"].split("/")[-2:])
        failed = True

        try:
            response = requests.get(BASE + webhook)
            if response.status_code != 200:
                raise Exception

            rss = feedparser.parse(TF2_RSS)

            response = requests.post(BASE + webhook, params={ 'wait': True }, json={
                    "content": "Webhook successfully registered! Here's an example",
                    "embeds": [format_embed(random.choice(rss['entries']))]
            })
            if response.status_code != 200:
                raise Exception

            with open("webhooks", "r") as f:
                webhooks = set(f.readlines())

            webhooks.add(webhook + "\n")

            with open("webhooks", "w") as f:
                f.write("".join(webhooks))

            failed = False

        except:
            pass

    return render_template("index.html", failed=failed)



def format_embed(entry):
    soup = bs4.BeautifulSoup(entry['summary'], "html.parser")

    try:
        image = soup.img["src"]
    except TypeError:
        image = None

    return {
        "title": entry["title"],
        "description": soup.get_text()[:2000],
        "url": entry["id"],
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", entry["published_parsed"]),
        "color": COLOR,
        "image": { "url": image },
    }



@application.route("/check", methods=["POST"])
def check():
    out = []

    with open("last_update") as last_update_file:
        last_update = float(last_update_file.read())

    rss = feedparser.parse(TF2_RSS, modified=time.localtime(last_update))
    if rss.status == 304:
        return "nothing new"

    payload = {
            "content": CONTENT,
            "embeds": [
                format_embed(entry) for entry in rss["entries"]
                if time.mktime(entry["published_parsed"]) > last_update
            ]
        }

    latest_update = time.mktime(rss["updated_parsed"])

    with open("last_update", "w") as last_update:
        last_update.write(str(latest_update))

    valid_webhooks = set()

    with open("webhooks") as webhooks:
        for webhook in webhooks:
            response = requests.get(BASE + webhook[:-1], headers={'content-type': 'application/json'})
            if response.status_code != 200:
                out.append("GET({r.status_code}: {r.reason}) {r.text} {r.url}".format(r=response))
                continue

            response = requests.post(BASE + webhook[:-1], json=payload)
            if response.status_code >= 300:
                out.append("POST({r.status_code}: {r.reason}) {r.text} {r.url}".format(r=response))
                continue

            valid_webhooks.add(webhook)

    with open("webhooks", "w") as webhooks:
        webhooks.write("".join(valid_webhooks))

    return "\n".join(out)
