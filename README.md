# Snort-PulledPork-BashScript

This script will install Snort IDS and the most updated rulesets from pulledpork.

It will also create a crontab to check for new rules hourly, a snort system service will also be created to run on startup.

This is a work in progress and was designed for Ubuntu 16.04 (Xenial Xerus).

I will not be held responsible for damage to any systems this script causes. Use at own discretion.

Please let me know of any changes to improve this script and automate the tedious task on installing snort

# Change these variables in the script for your specific system:

-- line 64: ipvar HOME_NET X.X.X.X <---- change to IDS Server IP.

-- line 72 & 78 & 122: interface <----- change to the listening interface (eg. eth0)

-- line 93 & 94: your oinkcode <----- change to your oinkcode given when registered for Snort






