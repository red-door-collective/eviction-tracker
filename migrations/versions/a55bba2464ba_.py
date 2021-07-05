"""empty message

Revision ID: a55bba2464ba
Revises: dafb40b232f1
Create Date: 2021-07-05 15:28:55.993828

"""
from alembic import op
import sqlalchemy as sa
from datetime import date


# revision identifiers, used by Alembic.
revision = 'a55bba2464ba'
down_revision = 'dafb40b232f1'
branch_labels = None
depends_on = None

today = str(date.today())


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('judgements', sa.Column(
        'file_date', sa.Date(), nullable=False, server_default=today))
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('judgements', 'file_date')
    # ### end Alembic commands ###
