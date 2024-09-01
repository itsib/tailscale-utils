#!/bin/bash

set -e

SERVICES_PATH="/etc/systemd/system"
BIN_PATH="/usr/sbin"

function msg {
    case "$1" in
    i) echo -e "\x1b[0;37m  $2\x1b[0m" ;;
    s) echo -e "\x1b[0;92m✔ $2\x1b[0m" ;;
    e) echo -e "\x1b[0;91m✗ $2\x1b[0m" ;;
    *) echo -e "\x1b[0;96m🪐 $@\x1b[0m\n" ;;
    esac
}

function install_service {
    msg i "Copy the executable files"
    cp tailscale-update.service "$SERVICES_PATH/tailscale-update.service"
    cp tailscale-update.timer "$SERVICES_PATH/tailscale-update.timer"
    cp tailscale-update "$BIN_PATH/tailscale-update"
    msg s "Files copied"

    msg i "Verify instalation"
    systemd-analyze verify /etc/systemd/system/tailscale-update.*
    msg s "Intalation verified"

    msg i "Enabling & starting services"
    systemctl --quiet enable tailscale-update.timer
    systemctl --quiet start tailscale-update.timer
    msg s "Services are running"

    msg s "The installation is complete\n"
}

function remove_service {
    state=$(systemctl is-enabled tailscale-update.timer 2>&1)
    if [ "$state" == "enabled" ]; then
        msg i "Stopping & disabling services"
        systemctl --quiet stop tailscale-update.timer
        systemctl --quiet disable tailscale-update.timer
        msg s "Services have been stopped"
    else
        msg i "There are no running services. Skip."
    fi

    msg i "Deleting the installation files"
    local is_removed=
    if [ -f "$SERVICES_PATH/tailscale-update.service" ]; then
        rm "$SERVICES_PATH/tailscale-update.service"
        is_removed="removed"
    fi

    if [ -f "$SERVICES_PATH/tailscale-update.timer" ]; then
        rm "$SERVICES_PATH/tailscale-update.timer"
        is_removed="removed"
    fi

    if [ -f "$BIN_PATH/tailscale-update" ]; then
        rm "$BIN_PATH/tailscale-update"
        is_removed="removed"
    fi

    if [ "$is_removed" == "removed" ]; then
        msg s "The tailscale-update service has been successfully removed"
    else
        msg e "No installed files were found."
    fi
    echo ""
    exit 0
}

msg "Tailscale utils"

if [[ "$@" == "install" ]]; then
    install_service
elif [[ "$@" == "remove" ]]; then
    remove_service
else
    msg e "Action is required, install or remove\n"
fi
