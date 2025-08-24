# Estado del proyecto: ParcelFlow

Resumen
- Objetivo: dejar el repo reproducible con docker-compose, dbt y Superset, manteniendo "SQL-first" para seeds.
- Estado actual: infraestructura y scripts principales añadidos o corregidos; Postgres, dbt y Superset arrancan, pero persisten problemas de orquestación dependientes del entorno Docker/WSL (redes y orden de arranque).

Qué se hizo
- Añadidos/actualizados: Makefile, .env.example, scripts/init/01_schema_and_seed.sql (semilla SQL corregida), scripts/load_seeds.sh, scripts/smoke.sh, .github/workflows/ci.yml.
- Se corrigieron archivos dbt: `profiles.yml`, `dbt_project.yml`, `models/schemas.yml` para evitar errores de parsing.
- `docker-compose.yml` ajustado para montar solo el SQL de inicialización, evitar ejecuciones inesperadas dentro del init y simplificar comandos de dbt/superset.

Archivos clave modificados/creados
- scripts/init/01_schema_and_seed.sql — reescrita para generar seeds válidos con generate_series.
- dbt/profiles.yml, dbt/dbt_project.yml, dbt/models/schemas.yml — correcciones de YAML y tests.
- Makefile — comandos convenientes (up, down, dbt, seed, smoke, clean) y detección de `docker compose` vs `docker-compose`.
- scripts/smoke.sh — pruebas de humo automáticas para validar la pila.
- .github/workflows/ci.yml — workflow CI para iniciar Postgres, ejecutar dbt y smoke tests.

Problemas pendientes (bloqueantes o relevantes)
- Error de red Docker: `Network needs to be recreated` en entornos WSL/ Docker Desktop. Actualmente la red `parcelflow_default` existe y contiene `parcelflow_pg`.
- dbt ocasionalmente falla con DNS al ejecutarse antes de que Postgres acepte conexiones. Recomendado: arrancar Postgres primero y esperar `pg_isready`.
- Superset arranque final depende de que la base de datos y dbt estén listos.

Pasos recomendados para arrancar localmente (desde la raíz del repo)
1. Recrear red y parar contenedores problemáticos:
   - docker-compose down -v
   - docker network rm parcelflow_default  # si existe y no está en uso
2. Iniciar Postgres y esperar:
   - docker-compose up -d postgres
   - timeout 60 bash -c 'until docker exec -i parcelflow_pg pg_isready -U ${POSTGRES_USER:-parcelflow} >/dev/null 2>&1; do sleep 1; done; echo "postgres ready"'
3. Verificar seeds / tablas:
   - docker exec -i parcelflow_pg psql -U parcelflow -d parcelflow -c "SELECT COUNT(*) FROM raw.raw_orders;"
4. Probar dbt:
   - docker-compose run --rm dbt dbt debug --profiles-dir .
   - docker-compose run --rm dbt dbt run --profiles-dir .
5. Levantar Superset y resto de servicios:
   - docker-compose up -d
6. Ejecutar pruebas de humo:
   - make smoke

Comandos de diagnóstico útiles
- Ver logs de Postgres: `docker logs parcelflow_pg --tail 200`
- Ver estado de la red: `docker network inspect parcelflow_default`
- Listar contenedores del proyecto: `docker ps --filter name=parcelflow`
- Ejecutar smoke script manual: `./scripts/smoke.sh`

Siguientes pasos recomendados
- Si usan WSL: reiniciar Docker Desktop / `wsl --shutdown` si aparecen problemas de red.
- Ajustar healthchecks si se desea bloqueos más estrictos (cuidado en WSL).
- Validar CI en GitHub Actions y ajustar timeouts si fallan tests por timing.

Si quieres, ejecuto los comandos de arranque y pego las salidas para diagnosticar el siguiente error.
