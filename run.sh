#!/bin/bash
# Hostctl - Quick run script
# Usage: ./run.sh [start|stop|status|restart]

PIDFILE="/tmp/hostctl.pid"

start() {
  echo "Starting infrastructure..."
  docker start rabby-db 2>/dev/null || docker run -d --name rabby-db -p 5432:5432 -e POSTGRES_PASSWORD=rabby_pg_pass postgres:16
  docker start hostctl-redis 2>/dev/null || docker run -d --name hostctl-redis -p 6379:6379 redis:7-alpine
  sleep 3

  echo "Starting Hostctl API server..."
  nohup /home/arixnetwork/hostctl/build/hostctl \
    --config /home/arixnetwork/hostctl/config.local.yaml server \
    > /tmp/hostctl.log 2>&1 &
  echo $! > "$PIDFILE"
  sleep 2

  # Register default admin if first run
  TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"email":"admin@hostctl.io","password":"Admin123!@#"}' 2>/dev/null | python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    curl -s -X POST http://localhost:8080/api/v1/auth/register \
      -H 'Content-Type: application/json' \
      -d '{"email":"admin@hostctl.io","password":"Admin123!@#","name":"Admin"}' > /dev/null 2>&1
  fi

  echo "Ready!"
  echo "  API:  http://localhost:8080"
  echo "  User: admin@hostctl.io / Admin123!@#"
}

stop() {
  if [ -f "$PIDFILE" ]; then
    kill $(cat "$PIDFILE") 2>/dev/null
    rm -f "$PIDFILE"
    echo "Stopped"
  else
    pkill -f "hostctl.*server" 2>/dev/null && echo "Stopped" || echo "Not running"
  fi
}

status() {
  if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "Running (PID $(cat $PIDFILE))"
    curl -s http://localhost:8080/health
    echo ""
  else
    echo "Not running"
  fi
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  restart) stop; sleep 1; start ;;
  status) status ;;
  *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac
