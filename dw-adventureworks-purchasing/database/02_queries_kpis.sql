
SELECT 
    t.ano,
    t.nome_mes,
    SUM(f.valor_total_pedido) AS valor_total_gasto
FROM FATO_PEDIDO_COMPRA f
JOIN DIM_TEMPO t ON f.fk_data_pedido = t.osk_tempo
GROUP BY t.ano, t.mes, t.nome_mes
ORDER BY t.ano, t.mes;


SELECT 
    fo.nome AS fornecedor,
    SUM(f.quantidade_recebida) AS total_recebido,
    SUM(f.quantidade_rejeitada) AS total_rejeitado,
    CASE 
        WHEN SUM(f.quantidade_recebida) > 0 
        THEN (CAST(SUM(f.quantidade_rejeitada) AS NUMERIC) / SUM(f.quantidade_recebida)) * 100
        ELSE 0 
    END AS taxa_rejeicao_percentual
FROM FATO_PEDIDO_COMPRA f
JOIN DIM_FORNECEDOR fo ON f.fk_fornecedor = fo.osk_fornecedor
GROUP BY fo.nome
ORDER BY taxa_rejeicao_percentual DESC;
