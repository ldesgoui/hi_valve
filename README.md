# TF2 Blog Discord Webhook

Posts a message when TF2.com releases a new entry on their RSS feed (could be Blog, News or Updates)


Depends on nix or python with feedparser, requests and beautifulsoup4 installed (change the shebangs)

To register a webhook, go to Server Settings -> Webhooks -> CReate and paste the URL given into `./webhooks` (one link per line)
Set a crontab to execute the script every so often


## TODO:
- Public instance with some interface to register new webhooks
