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

## LDAP/AD Sync
Syncs a list of LDAP or AD groups with Grafana teams.  This requires ldapsearch to be functioning properly on the Grafana instance.  The script verifies in both direction creating the users and groups, adding users to the correct groups, but also handling the removal of users from groups if removed in LDAP/AD, also the removal of groups if removed from the sync list or LDAP or AD.  

This script is meant to be used for instances that have their auth integrate with LDAP or AD.  However, when generating these user accounts it is required to give them a local password.  This script gives every user it creates a unique and random 32 charachter password that is generated dynamically and not saved at any point.  This password is irrevlevant as LDAP/AD authentication will grant the user access to the Grafana instance.  

This script is recommended to be run via cron at an interval to keep Grafana in sync with your auth infrastructure.  It can also be run in debug mode with the --debug flag which puts out a high verbosity log of what the script is doing.  

## Backup & Sync
These scripts can be set up to:
- Perfom and automated backup of Grafana's backing DB information that defines alerts/folders/dashboards/users/etc.
- Perform an automated sync of two or more Grafana instances
- Perform a restore of a Grafana backing DB following a migration or system failure

On the backend this is all done by quiesing and backuping up the database that underpins Grafana itself.  Currently sqlite3 and mariadb (mysql) backing db's are supported with pgsql support hopefully landing soon.  
