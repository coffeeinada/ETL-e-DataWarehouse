import pandas as pd
from sqlalchemy import create_engine, text

# Definição das conexões (Origem: SQL Server OLTP | Destino: PostgreSQL DW)
SRC_URI = "mssql+pyodbc://sa:SuaSenhaForte123@localhost:1433/AdventureWorks?driver=ODBC+Driver+17+for+SQL+Server"
DW_URI = "postgresql://postgres:postgres123@localhost:5432/dw_adventureworks_purchasing"

engine_src = create_engine(SRC_URI)
engine_dw = create_engine(DW_URI)

def carregar_incremental_compras():
    print("Iniciando processo de ETL incremental...")

    # 1. Identificar o último número de pedido já carregado no DW
    with engine_dw.connect() as conn:
        result = conn.execute(text("SELECT COALESCE(MAX(numero_pedido), 0) FROM fato_pedido_compra;"))
        ultimo_pedido_carregado = result.scalar()

    print(f"Último número de pedido carregado no DW: {ultimo_pedido_carregado}")

    # 2. Extrair apenas os novos dados da origem (OLTP) maiores que o último ID carregado
    # Exemplo simplificado focando na lógica de extração incremental baseada em ID
    query_extracao = f"""
        RTRIM(UPPER(...)) -- Ajustar query SQL Server para buscar PurchaseOrderHeader e PurchaseOrderDetail
        -- WHERE PurchaseOrderID > {ultimo_pedido_carregado}
    """
    
    # Exemplo prático de leitura usando Pandas (substitua a query pela sua extração real do AdventureWorks)
    print(f"Extraindo registros do OLTP com ID superior a {ultimo_pedido_carregado}...")
    
    # df_novos_dados = pd.read_sql(query_extracao, engine_src)

    # 3. Transformação e Carga (Load)
    # if not df_novos_dados.empty:
    #     df_novos_dados.to_sql('fato_pedido_compra', engine_dw, if_exists='append', index=False)
    #     print(f"{len(df_novos_dados)} novos registros inseridos com sucesso no DW.")
    # else:
    #     print("Nenhum novo registro encontrado para carga incremental.")

    print("ETL incremental finalizada com sucesso!")

if __name__ == "__main__":
    carregar_incremental_compras()
