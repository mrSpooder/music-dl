# music-dl

This script is meant to make downloading music from youtube easier.

Basically it downloads the audio from a given url (it may be a single video or
a playlist), embedds it with whatever metadata youtube-dl is able to find, and
writes the final download path to stdout. Optionally the user can specify
their own values for tags (these take precedence over the videos existing
metadata). I'd recommend specifying as many as possible because the
metadata in youtube videos is usually incomplete, and sometimes even wrong.

Also, music-dl can read from stdin and write to stdout, and therefor can be
used as a filter. For example, you could send the output to
[beets](https://beets.io/) to better tag and organize the music you downloaded.

## Dependencies

- [youtube-dl](https://youtube-dl.org/)
- [ffmpeg](https://ffmpeg.org/)

## Installation

`git clone https://github.com/segf00lt/music-dl && cd music-dl/ && sudo make install ;`

## TODO

- Test
- Improve error handling
- Make album split work with m4a (requires generating new MOOV atoms for each audio file created by `split()`)
- Improve timestamp recognition (fuzzier REGEX for matching timestamps and their titles)
- Write manpage
