mpv-notify
==========

Adds desktop notifications to the [mpv](https://mpv.io) media player on Mac,
with metadata like artist, album name and track name when the track changes.

Features
--------

* Shows artist, title and album name (as far as detected by mpv)
* Extracts cover art using ffmpeg

Requirements
------------

* [mpv](https://mpv.io) (>= 0.35)
* [Lua](https://lua.org) (>= 5.2)
* [ffmpeg](https://www.ffmpeg.org/)
* `convert` from [ImageMagick](https://www.imagemagick.org)
* [Alerter](https://github.com/vjeantet/alerter)

Installation
------------

Drop `notify.lua` into the folder `~/.config/mpv/scripts/` (create it when necessary),
and mpv will find it. Optionally, you can add it to mpv's command line:

    mpv --lua=/path/to/notify.lua <files and options>

License
-------

* Originally written by Roland Hieber <rohieb at rohieb.name>
* Improvements by deyloop <me.deyloop@gmail.com>
* Port to MacOS by me with a few enhancements
