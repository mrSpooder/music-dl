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
-d, --target-dir= : specify directory for download (defaults to $HOME/Music)
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
-q, --quiet : doesn't prompt the user for input (is assumed if no query fields are specified)
-i, --interactive : prompts the user for input
-h, --help : prints this message
" >&2 && exit 1 ;
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
		-i) MODE='2'; shift 2 ;;

		--target-url=*) URL="${1#*=}"; shift 1 ;;
		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--format) FMT="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--range=*) RANGE="${1#*=}"; shift 1 ;;
		--quiet) MODE='1'; shift 1 ;;
		--interactive) MODE='2'; shift 1 ;;

		-*) echo "error: unkown option $1" >&2 && err ;;
	esac
done

[[ -z $URL ]] && echo "error: missing target URL" >&2 && err;

HOSTNAME=$(echo $URL | sed -n 's/^https\?:\/\/\([^\/]\+\)\/\?.*$/\1/p')

[[ "$HOSTNAME" != "www.youtube.com" ]] && echo "error: unsupported URL" >&2 && exit 1;

TYPE=$(echo $URL | sed -n -e "s/https:\/\/$HOSTNAME\// /" -e "s/\?.*$/ /p" | tr -d ' ')

[[ -z $DIR && ! -d $HOME/Music ]] && mkdir $DIR;

[[ -z $ARTIST && -z $ALBUM && -z $SONG || "$MODE" != "2" ]] && MODE='1';

[[ -z $ALBUM ]] && ALBUM='album';

[[ -z $MODE ]] && MODE='0';

[[ -n $FMT && "$FMT" != "mp3" && "$FMT" != "m4a" ]] && echo "error: unsupported audio format, please use mp3 or m4a" >&2 && exit 1;

[[ -z $FMT ]] && FMT="mp3";

if [[ -d $TEMP_DIR ]]; then
	cd $TEMP_DIR;
else
	echo "error: tempdir not created" >&2 && exit 1;
fi

dl_video() {
	youtube-dl -o "$ALBUM/%(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
}

dl_playlist() {
	if [[ -n $RANGE ]]; then
		youtube-dl --playlist-items $RANGE -o "%(playlist_title)s/%(playlist_index)s %(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
	else
		youtube-dl -o "%(playlist_title)s/%(playlist_index)s %(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
	fi

	if [[ "$ALBUM" != "album" ]]; then
		mv $(ls) $ALBUM && echo "$ALBUM";
	else
		echo "$(ls)";
	fi
}

case $TYPE in
	playlist) ALBUM=$(dl_playlist) ;;
	watch) dl_video ;;
	*) echo "error: unsupported content type" >&2 && exit 1 ;;
esac

for file in $ALBUM; do
	[[ -f "$file" ]] && DATA=$(ffprobe "$file" 2>&1);

	[[ -z $(echo $DATA | grep -e "album[[:space:]]:" | tr -d "album :") && "$ALBUM" != "album" ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata album="$ALBUM" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "artist[[:space:]]:" | tr -d "artist :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata artist="$ARTIST" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | grep -e "title[[:space:]]:" | tr -d "title :") ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata title="$SONG" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
done

pwd && exit 0;
