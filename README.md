# glocken

[![Michaelskirche Entringen](https://www.breitenholz-entringen-evangelisch.de/fileadmin/_processed_/d/f/csm_2021-0523-Geb%C3%A4ude-Entringen-Kirche-P1000002_63bae670e9.jpg)](https://www.breitenholz-entringen-evangelisch.de/ "Website of our church community")

Simulator for the church bells in Entringen, Germany.
It can realistically reproduce the core schedule after which the bells are currently (2021) rung.
However, this schedule only includes chiming dependent on date and time, so special events like holidays, services, baptisms, funerals and concerts are not considered.

The following occasions are covered:

* 1-4 double-strokes for quarter past, half, three-quarter past and full hours
* Appropriate amount of strokes for full hours, first high, then low
* Morning chime on weekdays at 6am
* Cross chime on weekdays at 11am, variation on Fridays
* Noon chime everyday at noon
* Cross chime on weekdays at 3pm, variation on Fridays
* Evening chime everyday at 6pm (winter) or 8pm (summer)
* Ringing in Sunday every Saturday at 5pm

The detailed and thoughtful schedule as a whole was developed and is currently curated by sacristan Reinhold Bauer.
(The image link leads to a German article about a recent addition of new bells.)

[<img src="https://www.tagblatt.de/Bilder/Reinhold-Bauer-Archivbild-531671h.jpg" alt="Portrait of Reinhold Bauer" width="100px" />](https://www.tagblatt.de/Nachrichten/Von-der-Entringer-Michaelskirche-erklingen-am-Reformationstag-drei-neue-Glocken-351803.html)

## Usage

With no parameters supplied, the current system time will be used.
For testing and development, it is also possible to supply a time in 24-hour format (HH:MM) as the only parameter, allowing the simulation of arbitrary times.

For testing and demo purposes, it is also possible to chime individual bells.
This can be accomplished with the "chime" parameter.
Without a second parameter, Sunday will be rung in without loops, which essentially only plays the start and end samples.
Commands in the form of `./glocken.sh chime X` will chime the specified bell `X` for 5 seconds.
The official bell index is used for this, where 1 is the largest bell:

1. Dominika (D<sub>4</sub> + 8 Hz)
2. Betglocke (F<sub>4</sub> + 10.5 Hz)
3. Ave Maria (G<sub>4</sub> + 8 Hz)
4. Kreuzglocke (A<sub>4</sub> + 9 Hz)
5. Zeichenglocke (C<sub>5</sub> + 9 Hz)
6. Schiedglocke (D<sub>5</sub> + 8 Hz)
7. Taufglocke (F<sub>5</sub> + 9 Hz)
8. Michaelsglocke (G<sub>5</sub> + 9 Hz)
9. Osanna (B<sub>5</sub> + 2 Hz)

The above list also encloses the exact pitch of each bell in brackets.
Note, however, that this project currently only includes samples for bells 6, 4, 2 and 1!

Internally, audio output is generated by playing the required WAVE samples at the right time.
Each sample will be played by a newly forked audio player instance.
By adjusting the `sample` function, it is possible to configure audio players other than sox or adjust the volume.

## Dependencies

sox, bc, date, sleep, bash

Tested on Linux.
There might be small changes necessary for other setups.
For example, make sure that like the GNU version of sleep, your sleep command also accepts floating point numbers.
For audio output, you can also use (p)aplay or more complex programs like ffmpeg or mplayer.
However, most of them will not work reliably when executed via Cron.

## Automatic playback

Use crontab -e as unprivileged user to add the following line to execute the script every minute and check if something should be played:

`* * * * * /path/to/install/directory/glocken.sh 1> /dev/null`

At present, the script only actually plays audio on minutes 0, 15, 30 and 45, so if you would like to have a cleaner system log, use this line instead:

`0,15,30,45 * * * * /path/to/install/directory/glocken 1> /dev/null`
