import pandas as pd
from sqlalchemy import create_engine, text


SRC_URI = "mssql+pyodbc://sa:Your_password123@localhost:1433/AdventureWorks?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes"
DW_URI = "postgresql://postgres:postgres123@localhost:5432/dw_adventureworks_purchasing"

engine_src = create_engine(SRC_URI)
engine_dw = create_engine(DW_URI)

def carregar_incremental_compras():
    print("Iniciando processo de ETL incremental...")

    try:
        
        with engine_dw.connect() as conn:
            result = conn.execute(text("SELECT COALESCE(MAX(numero_pedido), 0) FROM fato_pedido_compra;"))
            ultimo_pedido_carregado = result.scalar()

        print(f"Último número de pedido carregado no DW: {ultimo_pedido_carregado}")

      
        query_extracao = f"""
            SELECT 
                oh.PurchaseOrderID AS numero_pedido,
                od.PurchaseOrderDetailID AS numero_item,
                CONVERT(INT, FORMAT(oh.OrderDate, 'yyyyMMdd')) AS fk_data_pedido,
                CONVERT(INT, FORMAT(oh.ShipDate, 'yyyyMMdd')) AS fk_data_envio,
                COALESCE(CONVERT(INT, FORMAT(od.DueDate, 'yyyyMMdd')), CONVERT(INT, FORMAT(oh.OrderDate, 'yyyyMMdd'))) AS fk_data_entrega,
                oh.VendorID AS fk_fornecedor,
                oh.EmployeeID AS fk_funcionario,
                od.ProductID AS fk_produto,
                oh.ShipMethodID AS fk_metodo_envio,
                oh.Status AS fk_status,
                od.OrderQty AS quantidade_pedida,
                od.UnitPrice AS preco_unitario,
                od.LineTotal AS valor_total_item,
                od.ReceivedQty AS quantidade_recebida,
                od.RejectedQty AS quantidade_rejeitada,
                od.StockedQty AS quantidade_estocada,
                oh.SubTotal AS subtotal_pedido,
                oh.TaxAmt AS valor_imposto,
                oh.Freight AS valor_frete,
                oh.TotalDue AS valor_total_pedido,
                od.UnitPrice AS preco_padrao_fornecedor,
                od.UnitPrice AS ultimo_preco_recebido
            FROM Purchasing.PurchaseOrderHeader oh
            INNER JOIN Purchasing.PurchaseOrderDetail od ON oh.PurchaseOrderID = od.PurchaseOrderID
            WHERE oh.PurchaseOrderID > {ultimo_pedido_carregado}
            ORDER BY oh.PurchaseOrderID, od.PurchaseOrderDetailID;
        """

        print("Extraindo novos dados do banco OLTP (SQL Server)...")
        df_novos = pd.read_sql(query_extracao, engine_src)

        if df_novos.empty:
            print("Nenhum novo registro encontrado. O Data Warehouse já está atualizado.")
            return

        print(f"Encontrados {len(df_novos)} novos registros para carga.")

     
        with engine_dw.connect() as conn:
            res_max_fato = conn.execute(text("SELECT COALESCE(MAX(sk_fato), 0) FROM fato_pedido_compra;"))
            ultimo_sk_fato = res_max_fato.scalar()

        df_novos.insert(0, 'sk_fato', range(ultimo_sk_fato + 1, ultimo_sk_fato + 1 + len(df_novos)))

      
        print("Carregando dados incrementais na tabela fato_pedido_compra...")
        df_novos.to_sql(
            'fato_pedido_compra', 
            engine_dw, 
            if_exists='append', 
            index=False,
            method='multi',
            chunksize=1000
        )

        print(f"ETL incremental finalizada com sucesso! {len(df_novos)} registros inseridos.")

    except Exception as e:
        print(f"Erro durante a execução da ETL incremental: {e}")
        raise e

if __name__ == "__main__":
    carregar_incremental_compras()
