#!/bin/bash

SERVICES_PATH="/etc/systemd/system"
BIN_PATH="/usr/sbin"

function msg {
    case "$1" in
    i) echo -e "\x1b[0;37m  $2\x1b[0m" ;;
    s) echo -e "\x1b[0;92m✔ $2\x1b[0m" ;;
    e) echo -e "\x1b[0;91m✗ $2\x1b[0m" ;;
    *) echo -e "\x1b[0;96m$1\x1b[0m" ;;
    esac
}

function usage {
  cat << EOF
The script for installing and removing the tail scale update service.
Support blocking bypass when updating the system (Error 451 Unavailable For Legal Reasons)

USAGE:
  ./install.sh install
  ./install.sh remove

EOF
}

function root_check {
    local user
    user=$(id -u)

    if [ "$user" != "0" ]; then
        msg e "Must be root; use sudo"
        exit 1
    fi
}

function install_service {
    msg i "Update the system files"
    cp tailscale-update.service "$SERVICES_PATH/tailscale-update.service"
    cp tailscale-update.timer "$SERVICES_PATH/tailscale-update.timer"
    cp tailscale-update "$BIN_PATH/tailscale-update"
    msg s "System files updated"

    msg i "Verify installation"
    systemd-analyze verify /etc/systemd/system/tailscale-update.*
    msg s "Installation verified"

    msg i "Enabling & starting services"
    systemctl --quiet enable tailscale-update.timer
    systemctl --quiet start tailscale-update.timer
    msg s "Services are running"

    msg s "The installation is complete\n"
}

function remove_service {
    local state
    state=$(systemctl is-enabled tailscale-update.timer 2>&1)
    if [ "$state" == "enabled" ]; then
        msg i "Stopping & disabling services"
        systemctl --quiet stop tailscale-update.timer
        systemctl --quiet disable tailscale-update.timer
        msg s "Services have been stopped"
    elif [ "$state" == "not-found" ]; then
        msg e "No installed files were found."
        exit 1
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
        msg s "The tailscale-update service has been successfully removed\n"
        exit 0
    else
        msg e "No installed files were found."
        exit 1
    fi
}

root_check

msg "🪐 Tailscale: $1"

if [ "$1" == "install" ]; then
    install_service
elif [ "$1" == "remove" ]; then
    remove_service
else
    msg e "Action is required, install or remove\n"
fi
