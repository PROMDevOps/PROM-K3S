#!/bin/bash

export $(xargs <../.env)

./backup.bash "promrub-${ENV}" "PG_SCB_USER" "PG_SCB_PASSWORD" "postgresql-scb-0" "scb"
