#!/bin/sh

################################
########### MUSIC-DL ###########
################################

CONFIG_DIR="$HOME/.config/music-dl"
CONFIG_FILE="$CONFIGDIR/config"
CACHE_DIR="$HOME/.cache/music-dl"
TEMP_DIR=$(mktemp -d 'music-dl.XXX')

err() {
echo "Usage: music-dl -u [TARGET URL] -a [ARTIST NAME] -A [ALBUM/EP TITLE]
Download music and appropriate metadata.

-u, --target-url= : specify target URL
-N, --artist-name= : artist name in single or double quotes
-A, --album-title= : album or EP title ibid.
-S, --song-title= : song title ibid.
-d, --target-dir= : specify directory for download (defaults to current directory)
-f, --format : specify audio format; ex: mp3,m4a,mp4 (defaults to mp3)
-h, --help : prints this message
-q, --quiet : doesn't prompt the user for input (is assumed if no query fields are specified)
-v, --verbose : puts beet in timid mode, see man beet (asks even if all the results are high certainty)" >&2 && exit 1 ;
}


while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) err ; ;;

		-u) URL="$2"; shift 2 ;;
		-N) ARTIST="$2"; shift 2 ;;
		-A) ALBUM="$2"; shift 2 ;;
		-S) SONG="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-f) FMT="$2"; shift 2 ;;
		-q) MODE='1'; shift 2 ;;
		-v) MODE='2'; shift 2 ;;

		--target-url=*) URL="${1#*=}"; shift 1 ;;
		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--format=*) FMT="${1#*=}"; shift 1 ;;
		--quiet) MODE='1'; shift 1 ;;
		--verbose) MODE='2'; shift 1 ;;

		-*) echo "unkown option: $1" >&2 && err ;;
	esac
done

[[ -z $URL ]] && echo "missing target URL" >&2 && err;

[[ -z $DIR && -d $HOME/Music ]] && DIR="$HOME/Music";

[[ -z $ARTIST && -z $ALBUM && -z $SONG || $MODE!='2' ]] && MODE='1';

[[ -z $MODE ]] && $MODE='0';

[[ -z $ALBUM ]] && ALBUM='album';

[[ -z $FMT ]] && FMT='mp3';

[[ -d $TEMP_DIR ]] && cd $TEMP_DIR;

youtube-dl -o "$ALBUM/%(title)s.%(ext)s" -i --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT; cp -r temp.$FMT {}; rm -rf temp.$FMT";

cd "$ALBUM";

for file in *; do
	[[ -f $file ]] && DATA=$(ffprobe $file 2>&1);

	[[ -z $(echo $DATA | grep -e "album[[:space:]]:" | tr -d "album :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata album="$ALBUM" "temp.$FMT" && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "artist[[:space:]]:" | tr -d "artist :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata artist="$ARTIST" "temp.$FMT" && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "title[[:space:]]:" | tr -d "title :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata title="$SONG" "temp.$FMT" && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
done

case "$MODE" in
	0) beet import -m "$DIR" "$ALBUM" ;;
	1) beet import -A -m "$DIR" -ql "$CACHE_DIR/log" `ls` ;;
	2) beet import -m -t "$DIR" "$ALBUM" ;;
esac


exit 0;
