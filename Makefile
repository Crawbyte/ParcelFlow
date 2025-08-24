.PHONY: up down dbt seed clock smoke clean

# Default values
HH ?= 09
MM ?= 00

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
	docker compose up

# Stop containers and remove volumes
down:
	docker compose down -v

# Run dbt models and tests
dbt:
	docker compose run --rm dbt dbt run --profiles-dir .
	docker compose run --rm dbt dbt test --profiles-dir .

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
