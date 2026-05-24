#!/bin/bash
# Hostctl - Start Control Panel
export PATH=/tmp/go/bin:$PATH

HOSTCTL_BIN=/home/arixnetwork/hostctl/build/hostctl
CONFIG=/home/arixnetwork/hostctl/config.local.yaml
PIDFILE=/tmp/hostctl.pid

case "${1:-start}" in
  start)
    echo "Starting Hostctl API server..."
    nohup "$HOSTCTL_BIN" --config "$CONFIG" server > /tmp/hostctl.log 2>&1 &
    echo $! > "$PIDFILE"
    echo "Started (PID $(cat $PIDFILE))"
    echo "Logs: /tmp/hostctl.log"
    echo "API: http://localhost:8080"
    ;;
  stop)
    if [ -f "$PIDFILE" ]; then
      kill $(cat "$PIDFILE") 2>/dev/null
      rm -f "$PIDFILE"
      echo "Stopped"
    else
      echo "Not running"
    fi
    ;;
  restart)
    $0 stop
    sleep 1
    $0 start
    ;;
  status)
    if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
      echo "Running (PID $(cat $PIDFILE))"
      curl -s http://localhost:8080/health
    else
      echo "Not running"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac
