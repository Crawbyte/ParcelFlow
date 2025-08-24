.PHONY: up down dbt seed clock smoke clean

# Default values
HH ?= 09
MM ?= 00

# Check for docker command and determine docker compose command
DOCKER_COMPOSE := $(shell if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "echo 'Error: Neither docker compose nor docker-compose found in PATH' >&2; exit 1"; fi)

# Help target
help:
	@echo "ParcelFlow Make Commands:"
	@echo "  make up      - Start all containers"
	@echo "  make down    - Stop all containers and remove volumes"
	@echo "  make dbt     - Run dbt models and tests"
	@echo "  make seed    - Load seed data from CSV files"
	@echo "  make clock   - Set simulation clock time (HH=09 MM=00 by default)"
	@echo "  make smoke   - Run smoke tests"
	@echo "  make clean   - Clean up temporary files"

# Start containers
up:
	$(DOCKER_COMPOSE) up

# Stop containers and remove volumes
down:
	$(DOCKER_COMPOSE) down -v

# Run dbt models and tests
dbt:
	$(DOCKER_COMPOSE) run --rm dbt run --profiles-dir .
	$(DOCKER_COMPOSE) run --rm dbt test --profiles-dir .

# Load seed data
seed:
	bash scripts/load_seeds.sh

# Set simulation clock
clock:
	@echo "Setting clock to $(HH):$(MM)"
	PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -c \
		"UPDATE control.sim_time SET current_sim_time = '2025-01-01 $(HH):$(MM):00';"

# Run smoke tests
smoke:
	bash scripts/smoke.sh

# Clean up
clean:
	rm -rf dbt/target dbt/logs
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete
