# TF2 Blog Discord Webhook

Posts a message when TF2.com releases a new entry on their RSS feed (could be Blog, News or Updates)

![Example](http://i.imgur.com/omEJwZ2.png)

## Usage

Depends on nix or python with feedparser, requests and beautifulsoup4 installed (change the shebangs)

To register a webhook, go to Server Settings -> Webhooks -> Create and paste the URL given into `./webhooks` (one link per line)  
Set a crontab to POST /webhooks/check every so often.

## TODO

- Check if webhook is dead every so often
- Customize message (and more?)
- Generic to any RSS (erlang rewrite?)
