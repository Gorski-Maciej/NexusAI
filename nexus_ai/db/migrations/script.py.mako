"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

NexusAI Database Migration
==========================

This migration was auto-generated from SQLModel metadata changes.
Review carefully before applying to production databases.

Migration type: ${migration_type if migration_type else 'schema_change'}
Risk level: ${risk_level if risk_level else 'low'}
Data migration required: ${data_migration if data_migration else 'no'}

"""
from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision: str = ${repr(up_revision)}
down_revision: Union[str, Sequence[str], None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    """Apply ${migration_type if migration_type else 'schema'} migration."""
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    """Revert ${migration_type if migration_type else 'schema'} migration."""
    ${downgrades if downgrades else "pass"}
