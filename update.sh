#!/bin/sh
# req: psql, jq, python3, jq

export firstArg="$1"
export sent=0

sql() { psql -A -P footer=off -P tuples_only=on -v "in='$(echo $@ | sed "s/'/''/g")'"; }

import(){
  sql $(curl -s $1) <<< 'select internal.import_xml(:in)' \
    | while read -r postUrl; do
      [ "$firstArg" == "--init" ] && break
      [ -z "$postUrl" ] && continue
      echo "Processing: $postUrl"
      local postDate=$(sql $postUrl <<< 'select date from post where url = :in')
      local postTitle=$(sql $postUrl <<< 'select title from post where url = :in')
      local postContent=$(sql $postUrl <<< 'select content from post where url = :in' \
          | python3 -c 'print(__import__("html").unescape(__import__("sys").stdin.read()))' \
          | python3 -c 'print(__import__("html").unescape(__import__("sys").stdin.read()))' \
          | sed 's/<[^>]*>//g'  \
          | head -c 1990 )
      local postImage=$(sql $postUrl <<< 'select content from post where url = :in' \
          | grep -o 'img src="[^"]*"' \
          | head -1 \
          | cut -d '"' -f 2)
      [ -z "$postImage" ] || postImage="{\"url\": \"$postImage\"}"
      [ -z "$postImage" ] && postImage='null'
      sql $postUrl <<< 'select internal.get_subscribers(:in)' \
        | while read -r webhook; do
          (jq -n \
            --arg url "$postUrl" \
            --arg date "$postDate" \
            --arg title "$postTitle" \
            --arg content "$postContent" \
            --argjson image "$postImage" \
            '{content: "<\($url)> (from <https://ldegoui.xyz/hi_valve>)", embeds:[{title: $title, description: $content, url: $url, timestamp: $date, image: $image}]}' \
            | curl -s -i -X POST -H "Content-Type: application/json" -d@- \
              "https://discordapp.com/api/webhooks/$webhook?wait=true" \
            | grep 'HTTP/.* 40[45]' \
            && sql $webhook <<< 'delete from internal.subscriber where webhook = :in' \
            && echo "Deleted: $webhook" \
          ) &
          sleep 0.5
      done
  done
}

import 'http://www.teamfortress.com/rss.xml'
import 'http://blog.counter-strike.net/index.php/feed/'
import 'http://blog.dota2.com/feed/'

