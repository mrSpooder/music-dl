# music-dl

This script simplifies downloading and tagging music from youtube. The
download functionality comes from youtube-dl, along with **very** simple
autotagging.

Basically it downloads the audio from a given url (it may
be a single video or a playlist), embedds it with whatever metadata
youtube-dl is able to find, and writes the final download path to stdout.
Optionally the user can specify their own values for tags. I'd recommend
specifying as many as you can bother because the metadata in youtube videos is
usually incomplete, and sometimes even wrong.

Because this script can read from stdin and write to stdout, it can be combined
with other programs. For example, you could pipe the output to
[beets](https://beets.io/) to better tag and organize the music you downloaded.

## Dependencies

- [youtube-dl](https://youtube-dl.org/)
- ffmpeg

## Installation

`git clone https://github.com/segf00lt/music-dl && cd music-dl/ && sudo make install ;`

## TODO

- Test
- Improve error handling
- Add interactive mode (if I take it off the TODO again it's never coming back)
- Make album split work with m4a
- Write manpage
