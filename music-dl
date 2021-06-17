#!/bin/sh

################################
########### MUSIC-DL ###########
################################

# variable declarations
CONFIG_DIR="$HOME/.config/music-dl/"
CONFIG_FILE="$CONFIGDIR/config"
API="https://musicbrainz.org/ws/2"
USER_AGENT="music-dl/0.1 ( https://github.com/mrSpooder/music-dl )"

# function declarations
err() {
echo "Usage: music-dl -u [TARGET URL] -a [ARTIST NAME] -A [ALBUM/EP TITLE]
Download music and appropriate metadata.

-u, --target-url= : specify target URL
-a, --artist-name= : artist name in single or double quotes
-A, --album-title= : album or EP title ibid.
-S, --song-title= : song title ibid.
-d, --target-dir= : specify directory for download (defaults to current directory)
-f, --format : specify audio format; ex: mp3,m4a,mp4 (defaults to mp3)
-h, --help : prints this message" >&2 && exit 1 ;
}

download_audio() {
	youtube-dl -o "%(title)s.%(ext)s" -i --geo-bypass --extract-audio --audio-format "$FMT" --audio-quality 0 "$URL";
}


# parse arguments
while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) err ; ;;

		-u) URL="$2"; shift 2 ;;
		-a) ARTIST="$2"; shift 2 ;;
		-A) ALBUM="$2"; shift 2 ;;
		-S) SONG="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-f) FMT="$2"; shift 2 ;;

		--target-url=*) URL="${1#*=}"; shift 1 ;;
		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--format=*) FMT="${1#*=}"; shift 1 ;;

		-*) echo "unkown option: $1" >&2 && err ;;
	esac
done

[[ -z $URL || -z $ARTIST || -z $ALBUM ]] && echo "missing target URL, artist name or album/EP title" >&2 && err;

[[ -z $DIR ]] && DIR=`pwd`;

[[ -z $FMT ]] && FMT='mp3';

cd '/tmp';

[[ -z $SONG ]] && wget --user-agent="$USER_AGENT" -O data.json "$API/release/?query=release:$ALBUM%20AND%20artistname:$ARTIST&fmt=json"

[[ -n $SONG ]] && wget --user-agent="$USER_AGENT" -O data.json "$API/recording/

# search for release: wget 'https://musicbrainz.org/ws/2/release/?query=release:"Wasting Light"%20AND%20artistname:"Foo Fighters"%20AND%20country:"US"&fmt=json' 
# get data for album and individual tracks: wget 'https://musicbrainz.org/ws/2/release/1a875005-f7eb-49ae-a20f-c66b5cc547a7?fmt=json&inc=recordings'
# search for recording
