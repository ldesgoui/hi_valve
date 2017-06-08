#!/bin/sh

alias psql="psql -A -P footer=off -P tuples_only=on"

export firstArg="$1"

import(){
    local sent=0
    for postUrl in $(psql -v "in='$(curl -s $1 | sed "s/'/''/g")'" <<< 'select internal.import_xml(:in)'); do
        [ "$firstArg" == "--init" ] && break
        alias psql="psql -v 'in=\"$postUrl\"'"
        local postDate = $(psql <<< 'select date from post where url = :in')
        local postTitle = $(psql <<< 'select title from post where url = :in')
        local postDescription = $(psql <<< 'select description from post where url = :in')
        local postImage = $(echo "$postDescription" | grep -o 'src="[^"]*"' | head -1 | cut -d '"' -f 2)
        [ -z "$postImage" ] && postImage="null"
        postDescription=$(echo "$postDescription" | sed 's/<[^>]*>//g' | python3 -c 'print(__import__("html").unescape(__import__("sys").stdin.read()))' | head -c 1990)
        for webhook in $(psql <<< 'select internal.get_subscribers(:in)'); do
           curl \
               -X POST \
               -H "Content-Type: application/json" \
               -d "{\"content\":\"<$postUrl> (from <https://ldesgoui.xyz/hi_valve)\",\"embeds\":[{\"title\":\"$postTitle\",\"description\":\"$postDescription\",\"url\":\"$postUrl\",\"timestamp\":\"$postDate\",\"image\":$postImage}]}" \
                "https://discordapp.com/api/webhooks/$webhook" &
           sent=$((sent + 1))
           [ $sent > 4 ] && sleep 2 && sent=0
       done
    done
}

import 'http://www.teamfortress.com/rss.xml'
import 'http://blog.counter-strike.net/index.php/feed/'
import 'http://blog.dota2.com/feed/'

