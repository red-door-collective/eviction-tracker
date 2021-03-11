"""empty message

Revision ID: b385db9a64e1
Revises: c2aa210b1c8a
Create Date: 2021-03-11 01:51:55.199460

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b385db9a64e1'
down_revision = 'c2aa210b1c8a'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('detainer_warrants', 'courtroom_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('detainer_warrants', 'courtroom_id',
               existing_type=sa.INTEGER(),
               nullable=False)
    # ### end Alembic commands ###
