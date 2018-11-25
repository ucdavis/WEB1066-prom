#!/bin/sh

echo 'Lets setup our env'

docker --version || echo 'Install docker'
heroku --version || echo 'Install heroku'

set -e
