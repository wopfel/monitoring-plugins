monitoring-plugins
==================

Some of my monitoring plugins that can be used by Icinga, for example.


## check_delock

Checks if the power state of a Delock Tasmota adapter is on.
I'm using this script to check a Delock model 11827.

Checks the today's energy. Raises a critical state if the today's
energy consumption exceeds the given energy when using `vars.delock_max1day` in host definition.

Example output having the power state on, and off, and off plus exceeding max. energy value for a day:

```
Ok: Server switch. Power status: ON. Today 0.066 kWh.
| powerstate=1 total=268.479 today=0.066 yesterday=0
[OK] Power status is ON
Version 12.3.1(tasmota)

Critical: Server switch. Power status: OFF. Today 0.066 kWh.
| powerstate=0 total=268.479 today=0.066 yesterday=0
[CRITICAL] Power status is OFF
Version 12.3.1(tasmota)

Critical: Hauswasserwerk. Power status: OFF. Today 1.036 kWh.
[CRITICAL] Power status is OFF
[CRITICAL] Max. energy for one day (0.200000) exceeds today's consumption (1.036)
Version 12.2.0(tasmota)
```

Command definition in Icinga:

```
object CheckCommand "delock" {
  command = [ "/usr/local/bin" + "/check_delock" ]

  arguments += {
    "--hostname" = "$address$"
    "--max1day" = {
        set_if = {{ string(macro("$delock_max1day$")) != "" }}
        description = "Max. energy for 1 day in kWh"
        value = "$delock_max1day$"
    }
    "--powerstatus" = {
        set_if = {{ string(macro("$delock_powerstatus$")) != "" }}
        description = "Desired power status: on, off, or ignore"
        value = "$delock_powerstatus$"
    }
  }
}
```

Service definition in Icinga (example):

```
apply Service "status" {
  import "generic-service"

  check_command = "delock"

  assign where match("delock-*", host.name)
}
```

Host definition in Icinga (example):

```
object Host "delock-hauswasserpumpe-keller" {
  import "generic-host"

  address = "192.168.209.8"

  vars.delock_max1day = 0.200
  vars.delock_powerstatus = "ignore"
}
```


## check_pacman

This plugin detects how many packages needs to be updated. It calls `pacman -Qu` to list all packages that needs an update.
Pacman is the package manager on Arch Linux. The plugin runs fine without root permission.

The plugin quits with exit code 1 if there's at least one package which needs to be updated.

You have to run `pacman -Sy` on your own to get the recent list of packages and package versions.

Example output:
> WARNING: 22 package(s) need updating. | packages=22

Since June 1st 2014 the age of the db files is checked, too. The plugin quits with exit code 1 if there are any db files older than 4 days.

Added another use lib definition so it runs on my Raspberry Pi. For this, NRPE and some monitoring plugins have to be installed. On my Pi, the plugins are installed in `/usr/share/nagios/libexec`. I've added `command[check_pacman]=/usr/local/bin/check_pacman` to the NRPE config file and restarted NRPE. You can use something like this as a service check definition:

    define service {
        use                             service-template
        host_name                       the-raspberry-pi-hostname-or-ip-address
        service_description             Pacman
        check_command                   check_nrpe!check_pacman
    }


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


## check_virtualization

Just a quick-n-dirty solution for checking virtual machines (VMs) and containers (LXC) on a proxmox host, including perfdata.

Internally, the commands "pct list" and "qm list" are used.

The result is:

```
OK: 9/10 containers running, 14/14 VMs running. | lxc_running=9 lxc_total=10 qm_running=14 qm_total=14
[OK] container testct1 is stopped
```

For stopped containers matching the pattern `testct*` there is no error raised.

Service definition in Icinga (example):

```
apply Service "virtualization" {
  import "generic-service"

  check_command = "by_ssh"

  vars.by_ssh_command = [ "/usr/bin/sudo", "/usr/local/bin/check_virtualization" ]
  vars.by_ssh_logname = "icinga"
  if ( host.vars.virtualization_stopped ) {
      vars.by_ssh_arguments += {
        "--stopped" = {
          value = host.vars.virtualization_stopped
        }
      }
  }

  assign where host.vars.checkbyssh == true && match("proxmox*", host.name)
}
```

Host definition in Icinga (example):

```
object Host "proxmox1" {
  import "generic-host"

  address = "..."

  vars.virtualization_stopped = "lxc7,vm42"
}
```


## check_lxc-info

Checks the output of `lxc-info LXC_ID` and gives some performance data. Tested on Proxmox.

Info: the perfdata may not be valid syntax (seconds/s, M/MiB). TODO: check that.

```
/usr/local/bin/check_lxc-info 510
OK: running, pid 20483. | CPU_use=1434.45seconds BlkIO_use=429.38MiB Memory_use=196.00MiB KMem_use=44.29MiB TX_bytes=99.28MiB RX_bytes=519.86MiB
```

Raises UNKNOWN if the container is not found and CRITICAL if the container is not in a running state.

Requires root privileges (with sudo, for example).


## check_pihole_updates

Uses command `pihole -up --check-only` on the locally installed pihole.
Returns whether there are any updates for core, web interface, or FTL.

Service definition in Icinga2 using SSH:

```
apply Service "pihole updates" {
  import "generic-service"

  check_command = "by_ssh"

  vars.by_ssh_command = [ "/usr/bin/sudo", "/usr/local/bin/check_pihole_updates" ]
  vars.by_ssh_logname = "icinga"

  assign where match("pihole*", host.name)
}
```

Sample output:

```
# /usr/local/bin/check_pihole_updates
Pi-Hole: 0 update(s) available. | updates=0 core=0 webui=0 ftl=0
```


## check_proxmox_lv

Checks the free space of a LVM logical volume. If you have a file system on an LV, you don't need this check script. You can use df based utilities for checking the file system (check_disk from the official monitoring-plugins, for example).

On my proxmox host, I have an LV for hosting thin logical volumes (created with lvcreate -T ...).

This plugin cares about the usage of the "master" logical volume. The thresholds are hard-coded: warning when > 80, critical when > 90 %.

Example usage:

```
# /usr/local/bin/check_proxmox_lv vg_ssd_evo/vms3
OK: LV vg_ssd_evo/vms3. Allocated pool data 61.97 %, metadata 29.22 %. | alloc_pool_data_pct=61.97 alloc_meta_data_pct=29.22
```


## check_fhem, check_fhem_heizkoerper

Old files. Deprecated. Use check_fhem_v2 instead.


## check_fhem_v2

Checks Zigbee Ikea motion sensors for reachability, Homematic Heizkoerper for battery state, and Homematic motion sensors (also for battery state).

If you want to try this script, please adjust the script according to your environment, especially:

- the regex to match the desired object names in Fhem.

Example usage:

```
# /usr/local/bin/check_fhem_v2 --host fhem.lan --item bewegungsmelder
Fhem: alle Batterien ok

# /usr/local/bin/check_fhem_v2 --host fhem.lan --item motionsensors
Fhem: alle MotionSensors reachable

# /usr/local/bin/check_fhem_v2 --host fhem.lan --item heizkoerperthermostate
Fhem: alle Batterien ok
```

Sorry for the misleading item options. `bewegungsmelder` checks the battery state of Homematic motion sensors, whereas `motionsensors` checks the Zigbee Ikea motion sensors.

#TODO: regex as parameter  
#TODO: battery/reachable as parameter  


## check_rpi_gpio

Place this script on your Raspberry Pi. It scans for the GPIO files in the /sys directory. There's no alerting so far.

Call the script using by_ssh. Example:

```
apply Service "gpio-ports" {
  import "generic-service"

  check_command = "by_ssh"

  vars.sshplugindir = "/usr/local/bin"

  vars.by_ssh_command = [ vars.sshplugindir + "/check_rpi_gpio" ]
  vars.by_ssh_logname = "icinga"

  assign where host.name == "..."
}
```

Your login account on your Pi has to be granted access to the GPIO files. Example: `adduser icinga gpio`

Sample output:

```
# /usr/local/bin/check_rpi_gpio
Ok: 2 GPIO ports found.
| gpio_530=1 gpio_539=0 gpio_count=2 high_count=1 low_count=1
```


## TODO

* Make check scripts customizable using Getopt::Long


## Tests

I've added a test for `check_json_jq_timestamp`. To run the test, start a basic http server:

```
cd ./t/testdata
python3 -m http.server
```

The tests need the following additional components:

- jo
- python3

Then run the test: `prove t`.

Sample output:

```
t/20-check-json-jq-timestamp.t .. ok
All tests successful.
Files=1, Tests=2,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.18 cusr  0.01 csys =  0.22 CPU)
Result: PASS
```

After running the test, stop the python http server (Ctrl+C or similar).

