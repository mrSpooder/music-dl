#!/bin/sh

# music-dl

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM EXIT;

err() {
echo "Usage: music-dl -u [TARGET URL]
Download music from youtube.

-u, --target-url= : specify target URL
-N, --artist-name= : artist name in single or double quotes
-A, --album-title= : album or EP title ibid.
-S, --song-title= : song title ibid.
-d, --target-dir= : specify directory for download (defaults to $HOME/Music)
-a, --add : moves download to $DIR
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
-q, --quiet : only final directory is outputed
-i, --interactive : prompt for input fields during runtime
-h, --help : prints this message
" >&2 && exit 1 ;
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) err ;;

		-u) URL="$2"; shift 2 ;;
		-N) ARTIST="$2"; shift 2 ;;
		-A) ALBUM="$2"; shift 2 ;;
		-S) SONG="$2"; shift 2 ;;
		-f) FMT="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-a) ADD='1'; shift 1 ;;
		-R) RANGE="$2"; shift 2 ;;
		-q) MODE="1"; shift 1 ;;
		-i) MODE="2"; shift 1 ;;

		--target-url=*) URL="${1#*=}"; shift 1 ;;
		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--format) FMT="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--add) ADD='1'; shift 1 ;;
		--range=*) RANGE="${1#*=}"; shift 1 ;;
		--quiet) MODE="1"; shift 1 ;;
		--interactive) MODE="2"; shift 1 ;;

		-*) echo "error: unkown option $1" >&2 && err ;;
	esac
done

[[ -z $URL ]] && echo "error: missing target URL" >&2 && err;

HOSTNAME=$(echo $URL | sed -n 's/^https\?:\/\/\([^\/]\+\)\/\?.*$/\1/p')

[[ "$HOSTNAME" != "www.youtube.com" ]] && echo "error: unsupported URL" >&2 && exit 1;

TYPE=$(echo $URL | sed -n -e "s/https:\/\/$HOSTNAME\///" -e "s/\?.*$//p")

DIR="$HOME/Music"

[[ -z $DIR && ! -d $HOME/Music ]] && mkdir $DIR;

[[ -z $ALBUM ]] && ALBUM='album';

[[ -n $FMT && "$FMT" != "mp3" && "$FMT" != "m4a" ]] && echo "error: unsupported audio format, please use mp3 or m4a" >&2 && exit 1;

[[ -z $FMT ]] && FMT="mp3";

TEMP_DIR=$(mktemp -d '/tmp/music-dl.XXXXX')

if [[ -d $TEMP_DIR ]]; then
	cd $TEMP_DIR;
else
	echo "error: tempdir not created" >&2 && exit 1;
fi

[[ "$MODE" = "1" ]] && QUIET="-q";

dl_video() {
	youtube-dl $QUIET -o "$ALBUM/%(title)s.%(ext)s" --no-playlist --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
}

dl_playlist() {
	if [[ -n $RANGE ]]; then
		youtube-dl $QUIET --playlist-items $RANGE -o "%(playlist_title)s/%(playlist_index)s %(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
	else
		youtube-dl $QUIET -o "%(playlist_title)s/%(playlist_index)s %(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
	fi

	if [[ "$ALBUM" != "album" ]]; then
		mv "$(ls)" "$ALBUM" && echo "$ALBUM";
	else
		echo "$(ls)";
	fi
}

case $TYPE in
	playlist) ALBUM="$(dl_playlist)" ;;
	watch) dl_video ;;
	*) echo "error: unsupported content type" >&2 && exit 1 ;;
esac

pushd "$ALBUM" 1>/dev/null;

for file in *; do
	[[ ! -f "$file" ]] && continue;

	DATA=$(ffprobe -hide_banner -show_entries format_tags=album,title,artist -of flat -i "$file" 2>&1 | sed -n -e 's/format\.tags\.//' -e 's/"//gp')

	[[ -z $(echo $DATA | sed -n -e 's/album=//p') && "$ALBUM" != "album" ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata album="$ALBUM" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | sed -n -e 's/artist=//p') ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata artist="$ARTIST" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";

	[[ -z $(echo $DATA | sed -n -e 's/title=//p') ]] && ffmpeg -y -i "$file" -map 0 -c copy -metadata title="$SONG" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
done

popd 1>/dev/null;

if [[ -n $ADD ]]; then
	mv "$ALBUM" "$DIR" && cd .. && rm -fdr $TEMP_DIR && exit 0;
else
	echo "$(pwd)/$ALBUM" && exit 0;
fi
