<h1 align="center">📊 Projeto de TIA 2026.2 — Data Warehouse e ETL Incremental</h1>

<p align="center">
  <img src="http://img.shields.io/static/v1?label=STATUS&message=EM%20DESENVOLVIMENTO&color=GREEN&style=for-the-badge" alt="Status: Em desenvolvimento" />
  <img src="http://img.shields.io/static/v1?label=FERRAMENTA&message=PostgreSQL&color=BLUE&style=for-the-badge" alt="Ferramenta: PostgreSQL" />
  <img src="http://img.shields.io/static/v1?label=LINGUAGEM&message=Python&color=yellow&style=for-the-badge" alt="Linguagem: Python" />
  <img src="http://img.shields.io/static/v1?label=MODELO&message=Star%20Schema&color=orange&style=for-the-badge" alt="Modelo: Star Schema" />
</p>

---

## 📖 Índice

- [📄 Objetivo](#-objetivo)
- [👥 Grupo](#-grupo)
- [📋 Enunciado](#-enunciado)
- [✅ Atividades realizadas](#-atividades-realizadas)
- [📚 Referências](#-referências)

---

## 📄 Objetivo

Projeto acadêmico (TIA — Tecnologia da Informação Aplicada) cujo objetivo é exercitar os seguintes conceitos no desafio:

- Construção de processos de **ETL incremental**
- **Modelagem multidimensional** (Star Schema)
- Definição e implementação de indicadores (**KPIs**)
- **Engenharia de Dados** aplicada a Data Warehouse

> 💡 O foco principal do trabalho é avaliar a capacidade de **modelagem multidimensional**, sendo a implementação da ETL incremental parte fundamental da avaliação.

## 👥 Grupo

Este trabalho é formado por 3 membros:

| Membro | GitHub |
|---|---|
| Pedro Henrique Coelho Lovatti | [@pedrocoelho04](https://github.com/pedrocoelho04) |
| Debora Cupertiono De Araújo Lacerda | [@coffeeinada](https://github.com/coffeeinada) |
| João Henrique Silva Reis | — |

## 📋 Enunciado

Neste projeto foi criado um modelo de dados multidimensional para a construção de um **Data Warehouse** baseado no conjunto de dados **AdventureWorks**.

Foi restaurado o banco de dados AdventureWorks (OLTP) e analisado seu modelo relacional. A partir dessa análise, o grupo propôs um modelo multidimensional seguindo obrigatoriamente o padrão **Star Schema (Modelo Estrela)**.

### 🧭 Etapas seguidas

1. Avaliar o modelo de dados OLTP disponível;
2. Elaborar **10 indicadores** (métricas/KPIs);
3. Projetar um modelo estrela para suportar os indicadores definidos;
4. Implementar o Data Warehouse no banco de dados **PostgreSQL**;
5. Construir uma **ETL em Python** para popular o Data Warehouse;
6. A ETL deverá obrigatoriamente ser **incremental**, processando apenas registros novos ou modificados;
7. Implementar, via **SQL**, as consultas que comprovem o funcionamento dos indicadores propostos.

> ⚠️ **Observação do avaliador:**
> "Não será necessário desenvolver dashboard para visualização dos indicadores."

## ✅ Atividades realizadas

- [ ] Avaliar o modelo de dados do AdventureWorks (OLTP);
- [ ] Elaborar 10 indicadores (métricas/KPIs);
- [ ] Propor um modelo multidimensional seguindo o padrão Star Schema;
- [ ] Elaborar o diagrama do modelo estrela (Draw.io, PlantUML ou ferramenta similar);
- [ ] Construir uma ETL incremental em Python para popular o Data Warehouse;
- [ ] Implementar o Data Warehouse no PostgreSQL;
- [ ] Criar um repositório no GitHub para armazenar o projeto da ETL e os scripts do Data Warehouse;
- [ ] Escrever um artigo no padrão Unisales contendo:
  - [ ] Introdução
  - [ ] Fundamentação teórica (Modelagem Multidimensional e ETL)
  - [ ] Desenvolvimento
  - [ ] Considerações finais

### 📝 Conteúdo do desenvolvimento do artigo

- Modelo estrela proposto;
- Diagrama do modelo multidimensional;
- Dicionário de dados do Data Warehouse;
- Descrição detalhada da estratégia de ETL incremental adotada;
- Justificativa das decisões de modelagem;
- Link para o projeto da ETL no GitHub;
- Scripts SQL que comprovem a implementação dos indicadores.

> ⚠️ **Observação do Avaliador:**
> "O artigo possui peso significativo na avaliação, sendo fundamental para demonstrar a compreensão conceitual e técnica do trabalho desenvolvido".

## 📚 Referências

- **AdventureWorks** — [Instalação e configuração](https://learn.microsoft.com/pt-br/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms)
- **Download AdventureWorks2016** — [AdventureWorks2016.bak](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016.bak)
- **Modelo de dados AdventureWorks** — [Schema (blogdozouza)](https://blogdozouza.wordpress.com/wp-content/uploads/2019/10/adventureworks2008_schema.gif)
- **Star Schema (Modelo Multidimensional)** — [Wikipedia](https://en.wikipedia.org/wiki/Star_schema)
- **Guia UNISALES de Elaboração de Trabalhos Acadêmicos** — [PDF](https://unisales.br/wp-content/uploads/2024/07/NOVO-GUIA-DE-ELABORACAO-E-NORMALIZACAO-DE-TRABALHOS-ACADEMICOS-E-DE-PESQUISA-29.05.pdf)
