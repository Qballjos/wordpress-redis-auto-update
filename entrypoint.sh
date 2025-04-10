#!/bin/bash

# Start Redis
service redis-server start

# Start Apache in foreground
apachectl -D FOREGROUND