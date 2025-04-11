#!/bin/sh

# =====================
# modem-restarter.sh
# Asuswrt-Merlin Script for Modem Auto-Restart
# =====================
# To view logs:
#     grep modem-restarter /tmp/syslog.log
#

HOST="google.com"
PORT=80
_self="modem-restarter"
PIDFILE="/var/run/${_self}.pid"
MODEM_URL="http://192.168.100.1"
LOGIN_PATH="/goform/login"
RESTART_PATH="/goform/MotoSecurity"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:73.0) Gecko/20100101 Firefox/73.0"
ACCEPT_HEADERS="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
CONTENT_TYPE="application/x-www-form-urlencoded"
LOGIN_CREDENTIALS="loginUsername=*****&loginPassword=*****"

check_running_instance() {
    if [ -f "$PIDFILE" ]; then
        echo "Script is already running."
        exit 1
    fi

    echo $$ > "$PIDFILE"
    trap "rm -f -- '$PIDFILE'" EXIT
}

log_message() {
    logger -t "$_self" "$1"
}

login_and_restart_modem() {
    log_message "Attempting to log in..."

    local login_url="${MODEM_URL}${LOGIN_PATH}"
    local restart_url="${MODEM_URL}${RESTART_PATH}"
    local redirect_url=$(curl -X POST \
        -d "$LOGIN_CREDENTIALS" \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: $ACCEPT_HEADERS" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "Upgrade-Insecure-Requests: 1" \
        -s -o /dev/null -I -L -w "%{url_effective}" \
        "$login_url")

    if [[ "${redirect_url##*/}" == "MotoHome.asp" ]]; then
        log_message "Successfully logged in. Restarting modem..."
        sleep 1
        curl -X POST \
            -d "UserId=&OldPassword=&NewUserId=&Password=&PasswordReEnter=&MotoSecurityAction=1" \
            -H "User-Agent: $USER_AGENT" \
            -H "Accept: $ACCEPT_HEADERS" \
            -H "Content-Type: $CONTENT_TYPE" \
            "$restart_url" >/dev/null 2>&1
        log_message "Modem restart command sent."
    else
        log_message "Login failed. Unable to restart modem."
    fi
}

check_network_and_restart() {
    if ! /opt/bin/netcat -w 10 -z $HOST $PORT; then
        log_message "Network check failed. Attempting recheck..."
        sleep 10
        if ! /opt/bin/netcat -w 10 -z $HOST $PORT; then
            log_message "Network check failed again. Restarting modem..."
            login_and_restart_modem
        else
            log_message "Network recheck successful. No action needed."
        fi
    else
        log_message "Network check successful. No action needed."
    fi
}

check_running_instance
check_network_and_restart
