#!/bin/sh

# music-dl

trap "exit 1" SIGHUP SIGINT SIGKILL SIGTERM EXIT;

err() {
echo "Usage: music-dl [TARGET URL]

-an, --artist-name= : artist name in single or double quotes
-at, --album-title= : album or EP title in single or double quotes
-st, --song-title= : song title in single or double quotes
-tn, --track-number= : track number in single or double quotes
-d, --target-dir= : specify directory for download (defaults to $HOME/Music)
-a, --add : moves download to $DIR
-s, --split= : splits single auido file into multiple files based on timestamps (mp3 only)
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
-q, --quiet : only final directory is outputed
-i, --interactive : prompt for input fields during runtime
-h, --help : prints this message" >&2 && exit 1 ;
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
	[[ "$(ls)" != "$ALBUM" ]] && mv "$(ls)" "$ALBUM" && echo "$ALBUM";
else
	ls;
fi
}

org_tags() {
[[ -d "$ALBUM" ]] && cd "$ALBUM";
FF_TAG=("album" "artist" "title" "track")
TAG=("$ALBUM" "$ARTIST" "$SONG" "$TRACK")
for file in *; do
	[[ ! -f "$file" ]] && continue;
	exp="\(0*[0-9]*\ \)\(\S.\+\)\.[a-z0-9]\+"
	[[ -z $TRACK ]] && TAG[3]=$(echo "$file" | sed -ne "s/$exp/\1/p" | tr -d '[:alpha:][:space:][:punct:]&$_');
	i=0
	until [[ $i = 4 ]]; do
		[[ -n $SPLIT ]] && TAG[2]=$(echo "$file" | sed -ne "s/$exp/\2/p")
		if [[ $i = 0 ]]; then
			[[ -n "${TAG[$i]}" && "$ALBUM" != "album" ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${FF_TAG[$i]}=${TAG[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		else
			[[ -n "${TAG[$i]}" ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${FF_TAG[$i]}=${TAG[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		fi
		i=`expr $i + 1`
	done
done
cd .. ;
}

split() {
[[ -d "$ALBUM" ]] && cd "$ALBUM";
[[ ! -f $TIMESTAMPS ]] && echo "error: timestamps file does not exist" >&2 && exit 1;
orig="$(ls)";
track="1";
exp='^\(\S.\+\)\s\([0-9]*:\?[0-9]\+:[0-9]\+\)-\([0-9]*:\?[0-9]\+:[0-9]\+\)$'

while read -r line
do
	title="$(echo "$line" | sed -ne "s/$exp/\1/p")"
	temp="$(echo "$title" | sed -ne "s/\//_/p")"
	[[ -n $temp ]] && title="$temp";
	start_at="$(echo "$line" | sed -ne "s/$exp/\2/p")"
	stop_at="$(echo "$line" | sed -ne "s/$exp/\3/p")"

	ffmpeg -hide_banner -nostdin -y -f "$FMT" -i "$orig" -c copy -ss "$start_at" -to "$stop_at" "$track $title.$FMT" 2>/dev/null && track=`expr $track + 1`;
done < "$TIMESTAMPS" ;
rm -f "$orig";
cd .. ;
}

interactive() {
<< '###'
Make a simple web frontend where all the options and fields would be
presented on the page either as text boxes or check boxes, in such a
way that the user can clearly see all the options and modify them
easily until thet're satisfied and want to execute.
###
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) err ;;

		-an) ARTIST="$2"; shift 2 ;;
		-at) ALBUM="$2"; shift 2 ;;
		-st) SONG="$2"; shift 2 ;;
		-tn) TRACK="$2"; shift 2 ;;
		-f) FMT="$2"; shift 2 ;;
		-d) DIR="$2"; shift 2 ;;
		-a) ADD='1'; shift 1 ;;
		-s) SPLIT='1' && TIMESTAMPS="$2"; shift 2 ;;
		-r) RANGE="$2"; shift 2 ;;
		-q) MODE='1'; shift 1 ;;
		-i) MODE='2'; shift 1 ;;

		--artist-name=*) ARTIST="${1#*=}"; shift 1 ;;
		--album-title=*) ALBUM="${1#*=}"; shift 1 ;;
		--song-title=*) SONG="${1#*=}"; shift 1 ;;
		--track-number=*) TRACK="${1#*=}"; shift 1 ;;
		--format) FMT="${1#*=}"; shift 1 ;;
		--target-dir=*) DIR="${1#*=}"; shift 1 ;;
		--add) ADD='1'; shift 1 ;;
		--split=*) SPLIT='1' && TIMESTAMPS="${1#*=}"; shift 1 ;;
		--range=*) RANGE="${1#*=}"; shift 1 ;;
		--quiet) MODE='1'; shift 1 ;;
		--interactive) MODE='2'; shift 1 ;;

		-*) echo "error: unkown option $1" >&2 && err ;;

		*) URL="$1"; shift 1 ;;
	esac
done

[[ -z $URL ]] && URL=$(</dev/stdin) && [[ -z $URL ]] && echo "error: missing URL" >&2 && exit 1;

HOSTNAME=$(echo $URL | sed -n 's/^https\?:\/\/\([^\/]\+\)\/\?.*$/\1/p')

[[ -z $HOSTNAME || "$HOSTNAME" != "www.youtube.com" ]] && echo "error: bad or unsupported URL" >&2 && exit 1;

TYPE=$(echo $URL | sed -n -e "s/https:\/\/$HOSTNAME\///" -e "s/\?.*$//p")

[[ -z $TYPE || "$TYPE" != "playlist" && "$TYPE" != "watch" ]] && echo "error: unsupported content type" >&2 && exit 1;

DIR="$HOME/Music"

[[ -z $DIR && ! -d $HOME/Music ]] && mkdir $DIR;

[[ -z $ALBUM ]] && ALBUM='album';

[[ -n $FMT && "$FMT" != "mp3" && "$FMT" != "m4a" ]] && echo "error: unsupported audio format, please use mp3 or m4a" >&2 && exit 1;

[[ -z $FMT ]] && FMT="mp3";

TEMP_DIR=$(mktemp -d '/tmp/music-dlXXX')

[[ -n $SPLIT && "$FMT" != "mp3" ]] && FMT="mp3";

[[ -f $TIMESTAMPS ]] && cp "$TIMESTAMPS" "$TEMP_DIR/.timestamps" && TIMESTAMPS="$TEMP_DIR/.timestamps";

if [[ -d $TEMP_DIR ]]; then
	cd $TEMP_DIR;
else
	echo "error: tempdir not created" >&2 && exit 1;
fi

[[ "$MODE" = "1" ]] && QUIET="-q";

case $TYPE in
	playlist) ALBUM="$(dl_playlist)" && org_tags ;;
	watch)
		if [[ -n $SPLIT ]]; then
			dl_video && split && org_tags;
		else
			dl_video && org_tags;
		fi
	;;
esac

if [[ -n $ADD ]]; then
	if [[ -n "$ARTIST" ]]; then
		[[ ! -d "$DIR/$ARTIST" ]] && mkdir "$DIR/$ARTIST";
		cp -r "$ALBUM" "$DIR/$ARTIST" && cd .. && exit 0;
	else
		cp -r "$ALBUM" "$DIR" && cd .. && exit 0;
	fi
else
	echo "$(pwd)/$ALBUM" && exit 0;
fi
