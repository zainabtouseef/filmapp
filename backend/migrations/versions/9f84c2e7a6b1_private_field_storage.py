"""Widen private fields to preserve authenticated ciphertext without truncation."""

import sqlalchemy as sa
from alembic import op

revision = "9f84c2e7a6b1"
down_revision = "f8a9b0c1d2e3"
branch_labels = None
depends_on = None

PRIVATE_COLUMNS = {
    "location_properties": ["private_address_token"],
    "equipment_items": ["serial_token"],
    "safety_check_ins": ["latitude_token", "longitude_token"],
    "agency_invitations": ["contact_token"],
    "brand_profiles": ["billing_token"],
    "distributor_contacts": ["email_token", "phone_token"],
    "insurance_partner_profiles": ["license_number_token"],
}


def upgrade() -> None:
    for table, columns in PRIVATE_COLUMNS.items():
        for column in columns:
            op.alter_column(
                table,
                column,
                existing_type=sa.String(255),
                type_=sa.Text(),
                existing_nullable=True,
            )


def downgrade() -> None:
    connection = op.get_bind()
    for table, columns in PRIVATE_COLUMNS.items():
        for column in columns:
            longest = connection.execute(
                sa.text(f"SELECT MAX(CHAR_LENGTH({column})) FROM {table}")
            ).scalar()
            if longest and longest > 255:
                raise RuntimeError(
                    "Private ciphertext cannot be truncated; retain the widened schema."
                )
    for table, columns in PRIVATE_COLUMNS.items():
        for column in columns:
            op.alter_column(
                table,
                column,
                existing_type=sa.Text(),
                type_=sa.String(255),
                existing_nullable=True,
            )
