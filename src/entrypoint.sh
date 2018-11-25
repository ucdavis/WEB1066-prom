#!/bin/sh
#
# we use an entrypoint script here with PORT setting so that
# we can run this on heroku using containers
export SERVER_PORT="${PORT:-8080}"
echo "Arguments are $*"
echo "Working with ${SERVER_PORT}"

#
# This is the probot host that is collecting our metrics
echo "Configure PROBOT_HOST => ${PROBOT_HOST}"
sed -i "s/{{PROBOT_HOST}}/${PROBOT_HOST}/g" /etc/prometheus/prometheus.yml

echo "Starting up server"
"/bin/prometheus" \
    --storage.tsdb.path=/prometheus \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.console.templates=/etc/prometheus/consoles \
    --config.file=/etc/prometheus/prometheus.yml \
    --web.listen-address=0.0.0.0:${SERVER_PORT}
