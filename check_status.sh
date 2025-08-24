#!/bin/bash
# This script checks the status of the ParcelFlow services

echo "Checking container status..."
docker ps

echo -e "\nChecking container logs..."
docker-compose logs --tail=20 dbt
echo -e "\nSuperset logs:"
docker-compose logs --tail=20 superset
