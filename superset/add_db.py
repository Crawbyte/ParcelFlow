import os
from superset import app, db
from superset.models.core import Database


SQLA_URI = os.environ.get(
"PARCELFLOW_DB_URI",
"postgresql+psycopg2://parcelflow:parcelflow@postgres:5432/parcelflow",
)


with app.app_context():
    if not db.session.query(Database).filter_by(database_name="ParcelFlow").first():
        dbobj = Database(database_name="ParcelFlow", sqlalchemy_uri=SQLA_URI)
        db.session.add(dbobj)
        db.session.commit()