#!/bin/bash

set -e

# get probot scrap url
# curl http://${LOCAL_HOST_SCRAP}:3000/probot/metrics
export LOCAL_HOST_SCRAP=$(ifconfig en0|grep 'inet\s'|awk '{print $2}')
docker run -it -e LOCAL_HOST_SCRAP=${LOCAL_HOST_SCRAP} -p 9090:8080 build-prometheus
