"""empty message

Revision ID: 007864c7fca9
Revises: b385db9a64e1
Create Date: 2021-03-16 00:19:23.997316

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '007864c7fca9'
down_revision = 'b385db9a64e1'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('organizer',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('first_name', sa.String(length=255), nullable=False),
    sa.Column('last_name', sa.String(length=255), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('organizer')
    # ### end Alembic commands ###