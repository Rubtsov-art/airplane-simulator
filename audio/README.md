# Audio files

Put the game's original/licensed OGG files in this folder using these exact names:

- engine_loop.ogg — continuous aircraft engine
- flight_music.ogg — calm background music
- rain_loop.ogg — rain on windshield/fuselage
- wipers_loop.ogg — windshield wipers
- alarm_loop.ogg — cockpit emergency alarm
- button_click.ogg — cockpit/control click
- refuel_loop.ogg — fuel hose/refueling
- landing_success.ogg — successful flight sting
- flight_fail.ogg — crash/failure sting

The game safely runs when these files are absent. AudioManager automatically starts using them once they are added.

Engine audio is adaptive: pitch and volume increase with throttle.
