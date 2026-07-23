from flask import Blueprint

from app.api.admin_control import admin_control_blueprint
from app.api.analytics import analytics_blueprint
from app.api.app import app_blueprint
from app.api.auth import auth_blueprint
from app.api.bookings import bookings_blueprint
from app.api.contracts import contracts_blueprint
from app.api.director import director_blueprint
from app.api.health import health_blueprint
from app.api.insurance import insurance_blueprint
from app.api.marketplace import marketplace_blueprint
from app.api.operations import operations_blueprint
from app.api.payments import payments_blueprint
from app.api.projects import projects_blueprint
from app.api.specialist import specialist_blueprint
from app.api.trust_safety import trust_safety_blueprint
from app.api.verification import verification_blueprint

api_v1 = Blueprint("api_v1", __name__)
api_v1.register_blueprint(admin_control_blueprint)
api_v1.register_blueprint(health_blueprint)
api_v1.register_blueprint(app_blueprint)
api_v1.register_blueprint(auth_blueprint)
api_v1.register_blueprint(verification_blueprint)
api_v1.register_blueprint(marketplace_blueprint)
api_v1.register_blueprint(projects_blueprint)
api_v1.register_blueprint(bookings_blueprint)
api_v1.register_blueprint(contracts_blueprint)
api_v1.register_blueprint(director_blueprint)
api_v1.register_blueprint(payments_blueprint)
api_v1.register_blueprint(operations_blueprint)
api_v1.register_blueprint(insurance_blueprint)
api_v1.register_blueprint(specialist_blueprint)
api_v1.register_blueprint(trust_safety_blueprint)
api_v1.register_blueprint(analytics_blueprint)
