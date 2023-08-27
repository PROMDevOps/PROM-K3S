#!/bin/bash

export $(xargs <../.env)

./backup.bash "promrub-${ENV}" "PG_SCB_USER" "PG_SCB_PASSWORD" "postgresql-scb-0" "scb"
./backup.bash "promjodd-${ENV}" "PG_CARPARK_API_USER" "PG_CARPARK_API_PASSWORD" "postgresql-carpark-api-0" "carpark-api"
