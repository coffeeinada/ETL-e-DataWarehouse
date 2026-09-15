import pandas as pd
from sqlalchemy import create_engine, text


DW_URI = "postgresql://postgres:postgres123@localhost:5432/etl-warehouse"
engine_dw = create_engine(DW_URI)

def carregar_incremental_compras():
    print("Iniciando processo de ETL incremental...")

    
    with engine_dw.connect() as conn:
        result = conn.execute(text("SELECT COALESCE(MAX(numero_pedido), 0) FROM fato_pedido_compra;"))
        ultimo_pedido_carregado = result.scalar()

    print(f"Último número de pedido carregado no DW: {ultimo_pedido_carregado}")

    
    print("ETL incremental simulada e finalizada com sucesso!")

if __name__ == "__main__":
    carregar_incremental_compras()