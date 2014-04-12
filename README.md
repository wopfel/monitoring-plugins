monitoring-plugins
==================

Some of my monitoring plugins that can be used by Icinga, for example.


## check_pacman

This plugin detects how many packages needs to be updated. It calls `pacman -Qu` to list all packages that needs an update.
Pacman is the package manager on Arch Linux. The plugin runs fine without root permission.

The plugin quits with exit code 1 if there's at least one package which needs to be updated.

You have to run `pacman -Sy` on your own to get the recent list of packages and package versions.

Example output:
> WARNING: 22 package(s) need updating. | packages=22

