#!/bin/sh
set -e

HELP="anime1 - watch animes without pain

Usage: anime1 -h
       anime1 add URL
       anime1 see TITLE
       anime1 remove TITLE
       anime1 status [[TITLE] NEW_STATUS]

Options:
    -h, --help  Print this help and exit

Commands:
    add         Add an url to the list
    see         See the next episode of TITLE
    remove      Remove an anime by TITLE
    status      See or set the current status of all or one animes

Arguments:
    URL         An anime1 anime URL
    TITLE       Part of an anime title.
                Case insensitive, the first title to match is taken.
    NEW_STATUS  Integer, number of the episode in the serie"

PLAYER="see"
PLAYER_ARGS="-f"
DB_FILE="$HOME/.config/anime1/db"

get_episode_urls() {
    title="$1"
    base_url="$(get_base_url "$1")"

    curl -s "$base_url" \
    | tr \'\" "\n\n"    \
    | grep watch        \
    | grep -B 1 watched \
    | grep '://'
}

get_base_url() {
    title="$1"

    grep "$title" "$DB_FILE" \
    | cut -d ':' -f 3-
}

get_status() {
    title="$1"

    grep "$title" "$DB_FILE" \
    | cut -d ':' -f 1
}

set_status() {
    title="$( tr -d "/;\n" <<<"$1")"
    status="$(tr -d "/;\n" <<<"$2")"

    sed -i "/$title/s/^[^:]\\+:/$status:/" "$DB_FILE"
}

all_status() {
    total="$(get_episode_urls | wc -l)"
    sed 's/^\([0-9]\+\):\([^:]\+\):\(.*\)$/\2 [\1\/'"$total"'] (\3)/' "$DB_FILE"
}

add_anime() {
    base_url="$1"
    title="$(get_title "$base_url")"
    status=0

    echo "$status:$title:$base_url" >> "$DB_FILE"
}

remove_anime() {
    title="$(tr -d "/;\n" <<<"$1")"

    sed -i "/$title/d" "$DB_FILE"
}

get_title() {
    url="$1"

    echo "${url##*/}" | tr '-' ' '
}

current_url() {
    title="$1"
    base_url="$(grep "$title" "$DB_FILE" | head -1 | cut -d ':' -f 3-)"
    num="$(get_status "$title" | tr -d "/;\n")"

    get_episode_urls "$title" | sed -n "$((num + 1))p"
}

see_anime() {
    title="$1"

    "$PLAYER" $PLAYER_ARGS "$(current_url "$title")"

    current_status="$(get_status "$title")"

    if [ "$current_status" -eq "$(get_episode_urls | wc -l)" ] ; then
        remove_anime "$title"
    fi

    set_status "$title" "$((current_status + 1))"
}

(
    umask 077
    mkdir -p "${DB_FILE%/*}"
    touch "$DB_FILE"
)

if [ $# -eq 0 ] ; then
    exec echo "$HELP"
fi

case "$1" in
    add)
        if [ -z "$2" ] ; then
            echo "$HELP"
            exit 1
        fi

        url="$2"
        add_anime "$url"
    ;;

    see)
        if [ -z "$2" ] ; then
            echo "$HELP"
            exit 1
        fi

        title="$(tr 'A-Z' 'a-z' <<<"$2")"
        see_anime "$title"
    ;;

    remove)
        if [ -z "$2" ] ; then
            echo "$HELP"
            exit 1
        fi

        title="$(tr 'A-Z' 'a-z' <<< "$2")"
        remove_anime "$title"
    ;;

    status)
        if [ -z "$2" ] ; then
            all_status

        elif [ -z "$3" ] ; then
            title="$(tr 'A-Z' 'a-z' <<<"$2")"
            get_status "$title"

        else
            title="$(tr 'A-Z' 'a-z' <<<"$2")"
            new_status="$3"
            set_status "$title" "$new_status"
        fi
    ;;

    -h) ;& --help)
        echo "$HELP"
    ;;

    *)
        echo "$HELP"
        exit 1
    ;;
esac
