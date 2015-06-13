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

Since June 1st 2014 the age of the db files is checked, too. The plugin quits with exit code 1 if there are any db files older than 4 days.

Added another use lib definition so it runs on my Raspberry Pi. For this, NRPE and some monitoring plugins have to be installed. On my Pi, the plugins are installed in `/usr/share/nagios/libexec`. I've added `command[check_pacman]=/usr/local/bin/check_pacman` to the NRPE config file and restarted NRPE. You can use something like this as a service check definition:

> define service {
>     use                             service-template
>     host_name                       the-raspberry-pi-hostname-or-ip-address
>     service_description             Pacman
>     check_command                   check_nrpe!check_pacman
> }


## check_teledat631_traffic

This plugin is for getting data from the Teledat Router 631, a DSL router I've used some years ago. I don't know if this plugin still works.
I just want to share it, maybe it's useful for someone.

The DSL modem had a web interface showing the amount of DSL data passing by for the current month.
The plugin grabs the monthly consumption value and the maximum limit value and provides the consumption value as performance data.

The plugin doesn't check the values. It only reports errors if the plugin can't parse the values from the web interface.


## check_downornotworking

This plugin checks if the specified site (like google.com) is available using downornotworking.com.


## check_isitdownrightnow

This plugin checks if the specified site (like google.com) is available using isitdownrightnow.com.


## TODO

* Make check scripts customizable using Getopt::Long


