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
-s, --split=<path_to_timestamps> : splits single auido file into multiple files based on timestamps (mp3 only)
-r, --range= : specify range in playlist
-f, --format : specify audio format; supported formats: mp3, m4a (defaults to mp3)
-q, --quiet : only final directory is outputed
-h, --help : prints this message" >&2 && exit 1 ;
}

dl_video() {
youtube-dl $QUIET -o "$ALBUM/$TRACK\ %(title)s.%(ext)s" --no-playlist --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;
}

dl_playlist() {
[[ -n $RANGE ]] && RANGE="--playlist-items $RANGE"
youtube-dl $QUIET $RANGE -o "%(playlist_title)s/%(playlist_index)s %(title)s.%(ext)s" --add-metadata --geo-bypass -x --audio-format "$FMT" --audio-quality 0 "$URL" --exec "ffmpeg -hide_banner -y -i {} -map 0 -c copy -metadata comment=\"\" -metadata description=\"\" temp.$FMT 2>/dev/null; cp -r temp.$FMT {}; rm -rf temp.$FMT" 1>&2;

playlist_title="$(ls)"
[[ "$ALBUM" != "album" && "$ALBUM" != "$playlist_title" ]] && mv "$playlist_title" "$ALBUM";
echo "$ALBUM"
}

org_tags() {
[[ -d "$ALBUM" ]] && cd "$ALBUM";
KEY=("album" "artist" "title" "track")
VAL=("$ALBUM" "$ARTIST" "$SONG" "$TRACK")
exp="\(0*[0-9]*\ \)\(\S.\+\)\.[a-z0-9]\+"
for file in *; do
	[[ ! -f "$file" ]] && continue;
	VAL[3]=$(echo "$file" | sed -ne "s/$exp/\1/p" | tr -d '[:alpha:][:space:][:punct:]&$_');
	[[ -z $SONG ]] && VAL[2]=$(echo "$file" | sed -ne "s/$exp/\2/p")
	for i in 0 1 2 3; do
		if [[ $i = 0 ]]; then
			[[ -n "${VAL[$i]}" && "$ALBUM" != "album" ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${KEY[$i]}=${VAL[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		else
			[[ -n "${VAL[$i]}" ]] && ffmpeg -hide_banner -y -i "$file" -map 0 -c copy -metadata "${KEY[$i]}=${VAL[$i]}" "temp.$FMT" 2>/dev/null && cp -r "temp.$FMT" "$file" && rm -rf "temp.$FMT";
		fi
	done
done
cd .. ;
}

split() {
[[ -d "$ALBUM" ]] && cd "$ALBUM";
[[ ! -f $TIMESTAMPS ]] && echo "error: timestamps file not created" >&2 && exit 1;
orig="$(ls)";
track="1";
exp='^\(\S.\+\)\s\([0-9]*:\?[0-9]\+:[0-9]\+\)-\([0-9]*:\?[0-9]\+:[0-9]\+\)$'

while read -r line; do
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
		-s) SPLIT='1'; shift 1 ;;
		-r) RANGE="$2"; shift 2 ;;
		-q) MODE='1'; shift 1 ;;

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

		-*) echo "error: unkown option $1" >&2 && err ;;

		*) URL="$1"; shift 1 ;;
	esac
done

if [[ -z $URL ]]; then
	[[ ! -p /dev/stdin ]] && echo "error: missing URL" >&2 && exit 1;
	URL=$(</dev/stdin);
fi

HOSTNAME=$(echo $URL | sed -n 's/^https\?:\/\/\([^\/]\+\)\/\?.*$/\1/p')

[[ -z $HOSTNAME || "$HOSTNAME" != "www.youtube.com" ]] && echo "error: bad or unsupported URL" >&2 && exit 1;

TYPE=$(echo $URL | sed -n -e "s/https:\/\/$HOSTNAME\///" -e "s/\?.*$//p")

[[ -z $TYPE || "$TYPE" != "playlist" && "$TYPE" != "watch" ]] && echo "error: unsupported content type" >&2 && exit 1;

DIR="$HOME/Music"

[[ -z $DIR && ! -d $HOME/Music ]] && mkdir $DIR;

[[ -z $ALBUM ]] && ALBUM='album';

[[ -z $TRACK ]] && TRACK=0;

[[ -n $FMT && "$FMT" != "mp3" && "$FMT" != "m4a" ]] && echo "error: unsupported audio format, please use mp3 or m4a" >&2 && exit 1;

[[ -z $FMT ]] && FMT="mp3";

TEMP_DIR=$(mktemp -d '/tmp/music-dlXXX');

[[ ! -d $TEMP_DIR ]] && echo "error: tempdir not created" >&2 && exit 1;

[[ -n $SPLIT && "$FMT" != "mp3" ]] && FMT="mp3";

if [[ -n $SPLIT && -z $TIMESTAMPS ]]; then
	[[ -z $EDITOR ]] && EDITOR=vi;
	echo -e "# Enter timestamps in the form: 'title' 'begin'-'end'\n# format 'begin' and 'end' as '00:00' and '10:00' for example" > timestamps;
	$EDITOR timestamps && sed -i -e "s/\s*#.*$//g" -e "/^$/d" timestamps;
	[[ ! -s time ]] && echo "error: timestamps empty" >&2 && exit 1;
	TIMESTAMPS=timestamps;
fi

[[ -f $TIMESTAMPS ]] && cp "$TIMESTAMPS" "$TEMP_DIR/.timestamps" && TIMESTAMPS="$TEMP_DIR/.timestamps";

cd $TEMP_DIR;

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
