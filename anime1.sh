#!/bin/bash
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

PLAYER="mpv"
PLAYER_ARGS="--fullscreen"
DB_FILE="$HOME/.config/anime1/db"

if [ -t 1 ] ; then
    NONE="$(echo -ne "\e[0m")"
    GREEN="$(echo -ne "\e[32m")"
    YELLOW="$(echo -ne "\e[33m")"
    CYAN="$(echo -ne "\e[36m")"
else
    NONE=""
    GREEN=""
    YELLOW=""
    CYAN=""
fi

get_episode_urls() {
    if grep -q "^https\?://" <<< "$1" ; then
        base_url="$1"
    else
        base_url="$(get_base_url "$1")"
    fi

    curl -s "$base_url" \
    | tr \'\" "\n\n"    \
    | grep watch        \
    | grep -B 1 watched \
    | grep '://'
}

get_base_url() {
    title="$1"

    grep "$title" "$DB_FILE" \
    | cut -d ':' -f 4-
}

get_status() {
    title="$1"

    check_exists "$title" || fatal "No such anime"

    grep "$title" "$DB_FILE" \
    | cut -d ':' -f 1
}

set_status() {
    title="$( tr -d "/;\n" <<<"$1")"
    status="$(tr -d "/;\n" <<<"$2")"

    sed -i "/$title/s/^[^:]\\+:/$status:/" "$DB_FILE"
}

all_status() {
    format=$CYAN'\3'
    format="$format$YELLOW"' ['$NONE'\1'$YELLOW'\/'$NONE'\2'$YELLOW']'
    format="$format$YELLOW"' ('$GREEN'\4'$YELLOW')'$NONE

    sed 's/^\([0-9]\+\):\([0-9]\+\):\([^:]\+\):\(.*\)$/'"$format"'/' "$DB_FILE"
}

add_anime() {
    base_url="$(cut -d / -f -5 <<<"$1")"
    title="$(get_title "$base_url")"
    total="$(get_total "$base_url")"
    status=0

    echo "$status:$total:$title:$base_url" >> "$DB_FILE"
}

remove_anime() {
    title="$(tr -d "/;\n" <<<"$1")"

    sed -i "/$title/d" "$DB_FILE"
}

get_title() {
    url="$1"

    echo "${url##*/}" | tr '-' ' '
}

get_total() {
    base_url="$1"

    get_episode_urls "$base_url" \
    | wc -l
}

current_url() {
    title="$1"
    base_url="$(grep "$title" "$DB_FILE" | head -1 | cut -d ':' -f 4-)"
    num="$(get_status "$title" | tr -d "/;\n")"

    get_episode_urls "$title" | sed -n "$((num + 1))p"
}

see_anime() {
    title="$1"

    check_exists "$title" || fatal "No such anime"

    # Load balancing seems tricky for anime1, we often get 404 responses,
    # retry as long as necessary
    while !                               \
        curl -s "$(current_url "$title")" \
        | tr '"' '\n'                     \
        | grep '\.mp4?'                   \
        | tr '\n' '\0'                    \
        | xargs -0 "$PLAYER" $PLAYER_ARGS
    do
        true
    done

    current_status="$(get_status "$title")"
    total="$(grep "$title" "$DB_FILE" | cut -d : -f 2)"

    current_status="$((current_status + 1))"

    if [ "$current_status" -ge "$total" ] ; then
        remove_anime "$title"
    fi

    set_status "$title" "$current_status"
}

check_exists() {
    title="$1"
    grep -q "$title" "$DB_FILE"
}

fatal() {
    echo "$@" >&2
    exit 1
}

(
    umask 077
    mkdir -p "${DB_FILE%/*}"
    touch "$DB_FILE"
)

if [ $# -eq 0 ] ; then
    all_status
    exit 0
fi

case "$1" in
    add)
        if [ -z "$2" ] ; then
            fatal "$HELP"
        fi

        url="$2"
        add_anime "$url"
    ;;

    see)
        if [ -z "$2" ] ; then
            fatal "$HELP"
        fi

        title="$(tr '[:upper:]' '[:lower:]' <<<"$2")"
        see_anime "$title"
    ;;

    remove)
        if [ -z "$2" ] ; then
            fatal "$HELP"
        fi

        title="$(tr '[:upper:]' '[:lower:]' <<< "$2")"
        remove_anime "$title"
    ;;

    status)
        if [ -z "$2" ] ; then
            all_status

        elif [ -z "$3" ] ; then
            title="$(tr '[:upper:]' '[:lower:]' <<<"$2")"
            get_status "$title"

        else
            title="$(tr '[:upper:]' '[:lower:]' <<<"$2")"
            new_status="$3"
            set_status "$title" "$new_status"
        fi
    ;;

    -h) ;& --help)
        echo "$HELP"
    ;;

    *)
        fatal "$HELP"
    ;;
esac
