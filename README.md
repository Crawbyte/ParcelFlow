# ParcelFlow — SQL-first logistics simulator


**EN** · Minimal, explainable, SQL-first live simulation & forecasting demo using PostgreSQL + dbt + Apache Superset. 100% synthetic, NDA-free.


**ES** · Demo minimalista, explicable y **SQL‑first** de simulación en vivo y pronóstico con PostgreSQL + dbt + Apache Superset. Datos 100% sintéticos, sin NDA.


---


## 1) What is ParcelFlow? / ¿Qué es ParcelFlow?
A portfolio-ready micro-simulator of last‑mile logistics: 3 warehouses (North, Center, South), 24 vehicles, city grid, live **as‑of** KPIs and a transparent SQL forecast for the next 60 minutes.


---


## 2) Quickstart / Inicio rápido
```bash
# 1) bring up everything (Postgres seeds automatically, dbt builds, Superset boots)
docker compose up


# Superset will be available at http://localhost:8088 (user/pass: admin / admin)