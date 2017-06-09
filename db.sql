-- Copyright (c) 2017 ldesgoui
-- read file 'LICENSE' for details
begin;

-- PUBLIC

create table if not exists post
    ( url       text primary key
    , date      timestamp not null
    , title     text not null
    , content   text not null
    );


-- INTERNAL

create schema if not exists internal;


create table if not exists internal.subscriber
    ( webhook       text primary key
    , tf2           integer not null default 0
    , csgo          integer not null default 0
    , dota2         integer not null default 0
    );


create or replace function internal.import_xml(text)
returns setof text as $$
    INSERT INTO
        post
    SELECT
        (xpath('guid/text()', x))[1]::text as url,
        to_timestamp((xpath('pubDate/text()', x))[1]::text, 'Dy, DD Mon YYYY HH24:MI:SS +0000') as date,
        (xpath('title/text()', x))[1]::text as title,
        coalesce( (xpath('content:encoded/text()', x, ARRAY[ARRAY['content', 'http://purl.org/rss/1.0/modules/content/']]))[1]::text, (xpath('description/text()', x))[1]::text ) as content
    FROM
        unnest(xpath('/rss/channel/item', xmlparse(content $1))) as x
    ON CONFLICT (url) DO NOTHING
    RETURNING
        url
    ;
$$ language sql;


create or replace function internal.tf2_level(post post)
returns integer as $$
BEGIN
    if post.url not like '%teamfortress%' then
        return 0;
    elsif post.content ~ 'teamfortress\.com\/(?!post\.php)\w+' then
        return 1; -- contains a massive update (content has link to a unique tf2.com page)
    elsif post.title ilike '%update%' then
        return 2;
    else
        return 3;
    end if;
END
$$ language plpgsql;


create or replace function internal.csgo_level(post post)
returns integer as $$
BEGIN
    if post.url not like '%counter-strike%' then
        return 0;
    elsif post.content ~ 'counter-strike\.net\/(?!index\.php)\w+' then
        return 1;
    else
        return 2; -- no update-only because Valve arent coherent in their titling scheme
    end if;
END
$$ language plpgsql;


create or replace function internal.dota2_level(post post)
returns integer as $$
BEGIN
    if post.url not like '%dota%' then
        return 0;
    elsif post.content ~ 'www\.dota2\.com\/\d+' then
        return 1; -- link to a 70X update
    elsif post.title ilike '%update%' or post.title ilike '%patch%' then
        return 2;
    else
        return 3;
    end if;
END
$$ language plpgsql;


create or replace function internal.get_subscribers(text)
returns setof text as $$
DECLARE
    post post;
BEGIN
    SELECT
        *
    INTO
        post
    FROM
        post 
    WHERE
        url = $1
    ;

    IF NOT FOUND THEN
        raise 'Post not found: %', $1;
    END IF;

    RETURN QUERY SELECT
        webhook
    FROM
        internal.subscriber
    WHERE
           internal.tf2_level(post)   BETWEEN 1 AND tf2
        OR internal.csgo_level(post)  BETWEEN 1 AND csgo
        OR internal.dota2_level(post) BETWEEN 1 AND dota2
    ;
END;
$$ language plpgsql;


-- USER INPUT

create or replace function subscription(webhook text)
returns internal.subscriber as $$
    SELECT
        *
    FROM
        internal.subscriber
    WHERE
        webhook = $1
    ;
$$ language sql immutable strict security definer;


create or replace function subscribe(webhook text, tf2 integer default 0, csgo integer default 0, dota2 integer default 0)
returns internal.subscriber as $$
    INSERT INTO
        internal.subscriber
    VALUES
        ($1, $2, $3, $4)
    ON CONFLICT (webhook) DO UPDATE SET
        tf2     = $2,
        csgo    = $3,
        dota2   = $4
    RETURNING
        *
    ;
$$ language sql security definer;


create role hi_valve;
grant select on table post to hi_valve;
grant execute on function subscribe(text, integer, integer, integer) to hi_valve;
grant execute on function subscription(text) to hi_valve;


commit;
