# hi\_valve

## (previously TF2 Blog Discord Webhook)

Allows discordapp.com webhooks to receive notifications whenever tf2.com, dota2.com and/or counter-strike.net update their game/blog.

 - http://www.teamfortress.com/rss.xml
 - http://blog.dota2.com/feed/
 - http://blog.counter-strike.net/index.php/feed/


## FAQ:

> How do I unsubscribe?  
Delete the webhook from your Discord Server.

> Can you add another filter?  
Depends how feasible it is and how much sense it makes: if Valve aren't consistent in their formatting (like for CS:GO updates), it might just be impossible, if it's to filter in a temporary event, it will be useless after the event.

> Will you do this for my game?  
Depends on time I can spend and if it isn't a pain to fetch update informations. (It's gonna make me cry because the project's name won't make any sense anymore.)

> Can you hack my server from this?  
Webhooks only allow me to read the name and avatar of your webhook, as well as the identifiers of the server and channel (which are useless without a Bot in your server), and finally allows me to post a message with pretty formatting and embeds. Embeds and links could be used to mislead users to website they don't want to visit, but the Discord client warns whenever you click a link, making this a non-factor. Besides, the code is open-source. (no)


## Installing:

If you want to host your own version of this software, you'll need:

- postgresql (with libxml)
- postgrest
- UNIX shell
- cron
