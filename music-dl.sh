#!/bin/sh

# music-dl

TEMP_DIR=$(mktemp -d '/tmp/music-dl.XXXXX')
DIR="$HOME/Music"

err() {
echo "Usage: music-dl -u [TARGET URL]
Download music and appropriate metadata.

-u, --target-url= : specify target URL
-N, --artist-name= : artist name in single or double quotes
-A, --album-title= : album or EP title ibid.
-S, --song-title= : song title ibid.
-d, --target-dir= : specify directory for download (defaults to current directory)
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
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
		-f) FMT="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-R) RANGE="$2"; shift 2 ;;
		-q) MODE='1'; shift 2 ;;
		-v) MODE='2'; shift 2 ;;

		--target-url=*) URL="${1#*=}"; shift 1 ;;
		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--format) FMT="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--range=*) RANGE="${1#*=}"; shift 1 ;;
		--quiet) MODE='1'; shift 1 ;;
		--verbose) MODE='2'; shift 1 ;;

		-*) echo "error: unkown option $1" >&2 && err ;;
	esac
done

[[ -z $URL ]] && echo "error: missing target URL" >&2 && err;

[[ -z $DIR && ! -d $HOME/Music ]] && DIR="$HOME/Music" && mkdir $DIR;

[[ -z $ARTIST && -z $ALBUM && -z $SONG || $MODE!='2' ]] && MODE='1';

[[ -z $MODE ]] && MODE='0';

[[ -z $FMT ]] && FMT="mp3";

[[ -z $ALBUM ]] && ALBUM='album';

if [[ -d $TEMP_DIR ]]; then
	cd $TEMP_DIR;
else
	echo "error: tempdir not created" >&2 && exit 1;
fi

if [[ -n $RANGE ]]; then
	youtube-dl --playlist-items $RANGE --no-playlist -o "$ALBUM/%(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT";
else
	youtube-dl --no-playlist -o "$ALBUM/%(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT";
fi

for file in $ALBUM; do
	[[ -f "$file" ]] && DATA=$(ffprobe "$file" 2>&1);

	[[ -z $(echo $DATA | grep -e "album[[:space:]]:" | tr -d "album :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata album="$ALBUM" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "artist[[:space:]]:" | tr -d "artist :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata artist="$ARTIST" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "title[[:space:]]:" | tr -d "title :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata title="$SONG" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
done

case "$MODE" in
	0) beet import -m "$DIR" "$ALBUM" ;;
	1) beet import -A -m "$DIR" -ql "$TEMP_DIR/log" "$ALBUM" ;;
	2) beet import -m -t "$DIR" "$ALBUM" ;;
	*) echo "error: undefined mode" >&2 && exit 1 ;;
esac

exit 0;
