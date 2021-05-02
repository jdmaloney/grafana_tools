# Grafana Tools
Tools to Manage Grafana and Enhance its Capabilities

## General
This repo is meant to be cloned to the grafana instance iself and run from there; if you need to run these tools from an outside host you will need to modify the scripts to use a different URL.

## Bulk Alert
This tool allows for the bulk pausing/starting of alerts by "tag", or the pausing/starting of all alerts on a Grafana instance.  Also this tool can accept an alert ID to pause/start that alert programatically.  This can be useful when pausing a set of alerts for a system maintenance or other reason.  Also the ability to toggle alerts by ID is nice so that alerts can be paused on a schedule if they need to be to prevent errant alerts.  

A naming convention for this tool is assumed to leverage the "tag" feature.  We tag/prefix our alerts with a name in brackets eg. [System A] To pause/start alerts by tag you need to prefix them with a name in square brackets. 

Example Script Inovcations

Pause all alerts tagged for System A:
./alert_toggle.sh pause tag "System_A" 

Pause alert with ID 73:
./alert_toggle.sh pause id 73

Restart all alerts on a Grafana instance:
./alert_toggle.sh start tag all
