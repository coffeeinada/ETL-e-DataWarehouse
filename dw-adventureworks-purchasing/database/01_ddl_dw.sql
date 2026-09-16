
CREATE DATABASE dw_adventureworks_purchasing;


CREATE TABLE DIM_TEMPO (
    sk_tempo INT PRIMARY KEY,
    data DATE,
    dia INT,
    mes INT,
    nome_mes VARCHAR(50),
    trimestre INT,
    ano INT,
    dia_semana VARCHAR(50)
);

CREATE TABLE DIM_FORNECEDOR (
    sk_fornecedor INT PRIMARY KEY,
    id_fornecedor INT,
    nome VARCHAR(100),
    numero_conta VARCHAR(50),
    classificacao_credito INT,
    fornecedor_preferencial BOOLEAN,
    ativo BOOLEAN
);

CREATE TABLE DIM_FUNCIONARIO (
    sk_funcionario INT PRIMARY KEY,
    id_funcionario INT,
    nome VARCHAR(150),
    cargo VARCHAR(100),
    genero VARCHAR(20),
    data_contratacao DATE
);

CREATE TABLE DIM_PRODUTO (
    sk_produto INT PRIMARY KEY,
    id_produto INT,
    nome VARCHAR(150),
    numero_produto VARCHAR(50),
    linha_produto VARCHAR(50),
    classe VARCHAR(50),
    cor VARCHAR(50),
    fabricado_internamente BOOLEAN
);

CREATE TABLE DIM_METODO_ENVIO (
    sk_metodo_envio INT PRIMARY KEY,
    id_metodo INT,
    nome VARCHAR(100),
    preco_base NUMERIC(18,2),
    taxa_por_peso NUMERIC(18,2)
);

CREATE TABLE DIM_STATUS_PEDIDO (
    sk_status INT PRIMARY KEY,
    codigo_status INT,
    descricao VARCHAR(100)
);


CREATE TABLE FATO_PEDIDO_COMPRA (
    sk_fato INT PRIMARY KEY,
    fk_data_pedido INT REFERENCES DIM_TEMPO(osk_tempo),
    fk_data_entrega INT REFERENCES DIM_TEMPO(osk_tempo),
    fk_data_envio INT REFERENCES DIM_TEMPO(osk_tempo),
    fk_fornecedor INT REFERENCES DIM_FORNECEDOR(osk_fornecedor),
    fk_funcionario INT REFERENCES DIM_FUNCIONARIO(osk_funcionario),
    fk_produto INT REFERENCES DIM_PRODUTO(osk_produto),
    fk_metodo_envio INT REFERENCES DIM_METODO_ENVIO(osk_metodo_envio),
    fk_status INT REFERENCES DIM_STATUS_PEDIDO(osk_status),
    
    numero_pedido INT,
    numero_item INT,
    quantidade_pedida INT,
    preco_unitario NUMERIC(18,2),
    valor_total_item NUMERIC(18,2),
    quantidade_recebida INT,
    quantidade_rejeitada INT,
    quantidade_estocada INT,
    subtotal_pedido NUMERIC(18,2),
    valor_imposto NUMERIC(18,2),
    valor_frete NUMERIC(18,2),
    valor_total_pedido NUMERIC(18,2),
    preco_padrao_fornecedor NUMERIC(18,2),
    ultimo_preco_recebido NUMERIC(18,2)
);
