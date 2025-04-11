# modem-restarter

A self-hosted shell script for ASUSWRT-Merlin routers that automatically restarts your modem when the internet connection goes down.

## How It Works

The script performs a periodic check to determine if your internet connection is active. If it fails to connect to `google.com:80` twice in a row, it will attempt to log into your modem's admin interface and trigger a restart.

Logs can be viewed with:

```sh
grep modem-restarter /tmp/syslog.log
```

---

## Script Behavior

- Uses `netcat` to test connectivity to a remote host.
- On failure, rechecks after a 10-second delay.
- If both checks fail, sends a POST request to the modem to trigger a restart.
- Avoids multiple concurrent runs using a PID lock file.

---

## Installation

1. **Copy the script**  
   Save the script as `/jffs/scripts/modem-restarter`.

2. **Make it executable**  
   ```sh
   chmod +x /jffs/scripts/modem-restarter
   ```

---

## WAN Event Detection

Create a file named `/jffs/scripts/wan-event`:

```sh
#!/bin/sh
logger -t modem-restarter "WAN event detected: $1 $2"
if [ "$2" = "down" ]; then
    /jffs/scripts/modem-restarter &
fi
```

Make it executable:

```sh
chmod +x /jffs/scripts/wan-event
```

---

## Periodic Check

To set up a cron job that runs every minute, create `/jffs/scripts/services-start`:

```sh
#!/bin/sh
cru a modemRestarter "*/1 * * * * /jffs/scripts/modem-restarter"
```

Make it executable:

```sh
chmod +x /jffs/scripts/services-start
```

---

## Personal Usage

I personally use **both** WAN event detection and a cron-based schedule together.

---

## Credentials

Update the script with your modem's credentials:

```sh
LOGIN_CREDENTIALS="loginUsername=*****&loginPassword=*****"
```

---

## Requirements

- ASUSWRT-Merlin firmware
- `netcat` installed at `/opt/bin/netcat`
- Your modem must support HTTP POST-based reboot via its admin panel
