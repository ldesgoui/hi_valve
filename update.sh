#!/bin/sh

alias psql="psql -A -P footer=off -P tuples_only=on"

import(){ psql -v "in='$(curl -s $1 | sed "s/'/''/g")'" <<< 'select internal.import_xml(:in)'; }

import 'http://www.teamfortress.com/rss.xml'
import 'http://blog.counter-strike.net/index.php/feed/'
import 'http://blog.dota2.com/feed/'

# psql -c "select internal.get_subscribers('http://www.teamfortress.com/post.php?id=28998')"
