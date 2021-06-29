# music-dl

This script simplifies downloading and tagging music from youtube. The
download functionality comes from youtube-dl, along with **very** simple
autotagging.

Basically it downloads the audio from a given url (it may
be a single video or a playlist), embedding it with whatever metadata
youtube-dl is able to find, and changing some other things accordingly.
Optionally the user can specify their own values for tags. I'd recommend
specifying as many as you can bother because the metadata in youtube videos is
usually incomplete, and sometimes even wrong.

It can also pipe the path to the download to STDOUT, and therefor be combined
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
- Add [booksplit](https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/booksplit) like functionality
- Read URL from stdin if -u option isn't given (or get rid of -u entirely)
