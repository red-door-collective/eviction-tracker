"""empty message

Revision ID: 19bc2460d32b
Revises: 21f341a50bc8
Create Date: 2021-11-19 17:42:59.238210

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '19bc2460d32b'
down_revision = '21f341a50bc8'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('cases', sa.Column(
        'claims_possession', sa.Boolean(), nullable=True))
    op.execute("UPDATE cases SET claims_possession = 't' WHERE amount_claimed_category_id = 0 OR amount_claimed_category_id = 2")
    op.execute(
        "UPDATE cases SET claims_possession = 'f' WHERE amount_claimed_category_id = 1")
    op.drop_column('cases', 'amount_claimed_category_id')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('cases', sa.Column('amount_claimed_category_id', sa.INTEGER(
    ), server_default=sa.text('3'), autoincrement=False, nullable=False))
    op.execute(
        "UPDATE cases SET amount_claimed_category_id = 0 WHERE claims_possession = 't'")
    op.execute(
        "UPDATE cases SET amount_claimed_category_id = 1 WHERE claims_possession = 'f'")
    op.drop_column('cases', 'claims_possession')
    # ### end Alembic commands ###
