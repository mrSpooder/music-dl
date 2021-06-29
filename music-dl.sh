#!/bin/sh

# music-dl

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM EXIT;

err() {
echo "Usage: music-dl [TARGET URL]

-N, --artist-name= : artist name in single or double quotes
-A, --album-title= : album or EP title in single or double quotes
-S, --song-title= : song title in single or double quotes
-T, --track-number= : track number in single or double quotes
-d, --target-dir= : specify directory for download (defaults to $HOME/Music)
-a, --add : moves download to $DIR
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
-q, --quiet : only final directory is outputed
-i, --interactive : prompt for input fields during runtime
-h, --help : prints this message
" >&2 && exit 1 ;
}

dl_video() {
[[ -n $TRACK ]] && TRACK="$TRACK\ "
youtube-dl $QUIET -o "$ALBUM/$TRACK%(title)s.%(ext)s" --no-playlist --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" -metadata purl=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
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

org_tags() {
cd "$ALBUM" ;
FF_TAG=("album" "artist" "title" "track")
TAG=("$ALBUM" "$ARTIST" "$SONG" "$TRACK")
for file in *; do
	[[ ! -f "$file" ]] && continue;
	[[ -z $TRACK ]] && TAG[3]=$(echo "$file" | sed -n -e 's/\(0*[0-9]*\ \)\([A-Za-z0-9 ]*[&$-_\*]*[A-Za-z0-9 ]*\)\+\.[a-z0-9]\+/\1/p' | tr -d '[:alpha:][:space:]');
	i=0
	until [[ $i = 4 ]]; do
		DATA=$(ffprobe -hide_banner -show_entries format_tags=${FF_TAG[$i]} -of csv -i "$file" 2>&1 | sed -n -e 's/format,//p')
		if [[ $i = 0 ]]; then
			[[ -z $DATA && "$ALBUM" != "album" ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${FF_TAG[$i]}=${TAG[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		else
			[[ -z $DATA ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${FF_TAG[$i]}=${TAG[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		fi
		i=`expr $i + 1`
	done
done
cd .. ;
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) err ;;

		-N) ARTIST="$2"; shift 2 ;;
		-A) ALBUM="$2"; shift 2 ;;
		-S) SONG="$2"; shift 2 ;;
		-T) TRACK="$2"; shift 2 ;;
		-f) FMT="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-a) ADD='1'; shift 1 ;;
		-R) RANGE="$2"; shift 2 ;;
		-q) MODE="1"; shift 1 ;;
		-i) MODE="2"; shift 1 ;;

		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--track-number=*) TRACK="${1#*=}"; shift 1 ;;
		--format) FMT="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--add) ADD='1'; shift 1 ;;
		--range=*) RANGE="${1#*=}"; shift 1 ;;
		--quiet) MODE="1"; shift 1 ;;
		--interactive) MODE="2"; shift 1 ;;

		-*) echo "error: unkown option $1" >&2 && err ;;

		*) URL="$1"; shift 1 ;;
	esac
done

[[ -z $URL ]] && URL=$(</dev/stdin) && [[ -z $URL ]] && echo "error: missing URL" >&2 && exit 1;

HOSTNAME=$(echo $URL | sed -n 's/^https\?:\/\/\([^\/]\+\)\/\?.*$/\1/p')

[[ -z $HOSTNAME ]] && echo "error: bad URL" >&2 && exit 1;

[[ "$HOSTNAME" != "www.youtube.com" ]] && echo "error: unsupported URL" >&2 && exit 1;

TYPE=$(echo $URL | sed -n -e "s/https:\/\/$HOSTNAME\///" -e "s/\?.*$//p")

DIR="$HOME/Music"

[[ -z $DIR && ! -d $HOME/Music ]] && mkdir $DIR;

[[ -z $ALBUM ]] && ALBUM='album';

[[ -n $FMT && "$FMT" != "mp3" && "$FMT" != "m4a" ]] && echo "error: unsupported audio format, please use mp3 or m4a" >&2 && exit 1;

[[ -z $FMT ]] && FMT="mp3";

TEMP_DIR=$(mktemp -d '/tmp/music-dl.XXX')

if [[ -d $TEMP_DIR ]]; then
	cd $TEMP_DIR;
else
	echo "error: tempdir not created" >&2 && exit 1;
fi

[[ "$MODE" = "1" ]] && QUIET="-q";

case $TYPE in
	playlist) ALBUM="$(dl_playlist)" && org_tags ;;
	watch) dl_video && org_tags ;;
	*) echo "error: unsupported content type" >&2 && exit 1 ;;
esac

if [[ -n $ADD ]]; then
	mv "$ALBUM" "$DIR" && cd .. && rm -fdr $TEMP_DIR && exit 0;
else
	echo "$(pwd)/$ALBUM" && exit 0;
fi
