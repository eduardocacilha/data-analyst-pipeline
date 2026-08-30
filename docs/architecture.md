# Arquitetura

## Visão geral

```
                         ┌─────────────────────────────────────────────┐
                         │                 DATABRICKS                   │
                         │                                               │
  ┌───────────┐  Parquet │   ┌────────┐   dbt   ┌────────┐  dbt  ┌─────┐│   Power BI
  │  NYC TLC  │──────────┼──▶│ BRONZE │────────▶│ SILVER │──────▶│GOLD ││───────────▶ Dashboards
  │  (fonte   │  script  │   │ (raw,  │  (stg_*)│(limpo, │(marts)│(fct/││   + RLS
  │  pública) │  Python  │   │ Delta) │         │ tipado)│       │dim) ││
  └───────────┘          │   └────────┘         └────────┘       └─────┘│
        │                └─────────────────────────────────────────────┘
        ▼
  ┌───────────┐
  │  AWS S3   │  (raw/bronze zone — pouso do dado antes do Databricks ler)
  └───────────┘
```

## Por que arquitetura medalhão (bronze / silver / gold)?

- **Bronze**: cópia fiel do dado de origem + metadados técnicos de ingestão
  (quando chegou, de qual arquivo veio). Nunca se transforma regra de negócio
  aqui — serve como "fonte da verdade" caso precise reprocessar tudo.
- **Silver**: dado limpo, tipado, com nomes de coluna padronizados, duplicatas
  removidas, e testado (`not_null`, `unique`, etc). Ainda é granular (não
  necessariamente pronto pro BI).
- **Gold**: modelo dimensional (fatos e dimensões) ou agregações, otimizado
  para consumo — é o que o Power BI enxerga.

Essa separação existe para isolar responsabilidades: se uma regra de negócio
mudar, você refaz só a gold; se o schema de origem mudar, você conserta só a
bronze/silver.

## Papel de cada tecnologia

| Componente   | Responsabilidade                                                    |
|--------------|----------------------------------------------------------------------|
| S3           | Armazenamento barato e durável do dado bruto (data lake)             |
| Databricks   | Motor de processamento (Spark) + Delta Lake para tabelas versionadas |
| dbt          | Transformação declarativa em SQL, testes de dados, documentação      |
| Power BI     | Camada de consumo/visualização, com segurança (RLS)                   |

## Fluxo de dados passo a passo

1. `scripts/ingest_to_s3.py` baixa os arquivos Parquet da NYC TLC e sobe para
   `s3://<bucket>/raw/nyc_taxi/ano=YYYY/mes=MM/`.
2. Um notebook/Job no Databricks lê o raw do S3 e grava como tabela Delta na
   camada bronze (`bronze.nyc_taxi_trips`), com colunas técnicas adicionadas.
3. dbt roda os models de `staging/` (silver), aplicando limpeza e testes sobre
   a bronze.
4. dbt roda os models de `marts/` (gold), aplicando a modelagem dimensional
   (fatos e dimensões) sobre a silver.
5. Power BI conecta via Databricks SQL Warehouse direto na camada gold,
   com RLS aplicando filtro por usuário/role.

## Decisões em aberto

- **Databricks Community Edition vs trial de 14 dias**: a Community Edition é
  gratuita "para sempre", mas tem restrições para acessar storage externo
  (S3) diretamente — pode ser necessário usar `boto3`/`requests` dentro do
  notebook para buscar os dados, em vez de montar o S3 nativamente. O trial
  de 14 dias em uma conta AWS/Azure real permite configurar Unity Catalog e
  external locations, mais próximo do que se vê em produção. Vale decidir
  qual caminho seguir dado o tempo do projeto.
- **RLS estático vs dinâmico** no Power BI (Semana 7).
- **Orquestração**: usar Databricks Workflows (mais simples, nativo) ou
  introduzir uma ferramenta externa (Airflow) — para este projeto, Databricks
  Workflows é suficiente e evita complexidade desnecessária.
