# Roadmap — 8 semanas de mentoria

Objetivo geral: sair de "só SQL + BI" para um perfil de **Analytics Engineer** que
entende o pipeline de ponta a ponta — ingestão, transformação em camadas, testes,
orquestração e entrega em BI com governança de acesso (RLS).

Cada semana tem: **objetivo**, **entregáveis** e **perguntas para levar ao mentor**.

---

## Semana 1 — Fundamentos + Setup de contas + Ingestão raw

**Objetivo:** ter contas criadas, bucket S3 no ar, e os primeiros arquivos da NYC TLC
subidos para a camada raw/bronze do S3.

**Entregáveis:**
- Conta AWS (free tier) criada, usuário IAM com permissão só no bucket do projeto
  (nunca usar a conta root nem access keys amplas).
- Bucket S3 criado com estrutura `raw/`, `bronze/`, `silver/`, `gold/` (ou usar
  prefixos separados por camada).
- Conta Databricks (Community Edition ou trial de 14 dias) criada.
- Script `scripts/ingest_to_s3.py` funcionando: baixa 2-3 meses de dados
  Yellow Taxi (Parquet) e sobe para `raw/nyc_taxi/`.

**Perguntas para o mentor:**
- Community Edition vs trial de 14 dias: qual ele recomenda para esse tipo de
  projeto de portfólio (visto que Community Edition tem limitações de conexão
  com storage externo)?
- Boas práticas de nomenclatura de buckets/prefixos em empresas reais.

---

## Semana 2 — Databricks + camada Bronze

**Objetivo:** entender clusters, notebooks e o conceito de bronze (dado cru, só
com metadados de ingestão, sem transformação de negócio).

**Entregáveis:**
- Cluster Databricks configurado (single-node, para uso de estudo).
- Notebook `notebooks/01_bronze_ingestion.ipynb`: lê os Parquets do S3, adiciona
  colunas técnicas (`_ingested_at`, `_source_file`) e grava como tabela Delta
  na camada bronze.
- Entendimento prático de: Delta Lake, DBFS, diferença entre "mount" e leitura
  direta via `boto3`/`s3a://`.

**Perguntas para o mentor:**
- Qual o padrão de mercado para autenticação Databricks → S3 (instance profile,
  Unity Catalog external location, keys)?
- Como ele estrutura cluster policies em produção?

---

## Semana 3 — dbt conectado ao Databricks

**Objetivo:** sair do notebook e passar a usar dbt como ferramenta de
transformação declarativa.

**Entregáveis:**
- `dbt-databricks` instalado e `profiles.yml` configurado (host, http_path,
  token do cluster/warehouse).
- `dbt debug` passando.
- Fontes declaradas em `models/staging/_sources.yml` apontando para as tabelas
  bronze.
- Primeiro model simples rodando (`dbt run`) só para validar a conexão.

**Perguntas para o mentor:**
- Convenções de nome de projeto/schema que ele usa no dia a dia.
- Como versionar `profiles.yml` sem vazar credenciais (dbt Cloud vs
  variáveis de ambiente).

---

## Semana 4 — Camada Silver (staging)

**Objetivo:** models `stg_*` que limpam, tipam e padronizam o dado bronze —
sem ainda aplicar regra de negócio pesada.

**Entregáveis:**
- `stg_taxi_trips.sql`, `stg_payment_types.sql`, `stg_taxi_zones.sql` (seed).
- Testes genéricos do dbt: `not_null`, `unique`, `accepted_values`,
  `relationships`.
- Documentação inline (`description:` no `.yml`) de cada coluna importante.

**Perguntas para o mentor:**
- Quando ele decide criar uma camada `intermediate` vs ir direto pra `mart`.
- Como ele trata dados que falham nos testes (quarentena? falha o pipeline?).

---

## Semana 5 — Camada Gold (marts) + modelagem dimensional

**Objetivo:** entregar tabelas prontas para consumo — modelo estrela.

**Entregáveis:**
- `dim_date`, `dim_zone`, `dim_payment_type`, `fct_trips` (grão: 1 corrida).
- Pelo menos um model **incremental** (`materialized='incremental'`) para
  simular carga mensal sem reprocessar tudo.
- Métricas de negócio calculadas (ex: valor médio por milha, gorjeta % por zona).

**Perguntas para o mentor:**
- Estratégias de incremental load que ele usa (merge vs insert-only,
  detecção de late-arriving data).
- Como decidir granularidade de fato em projetos reais.

---

## Semana 6 — Documentação + Orquestração

**Objetivo:** o pipeline deixa de ser "rodado manualmente" e passa a ser
agendado e documentado.

**Entregáveis:**
- `dbt docs generate` + lineage gerado e revisado.
- Databricks Workflow (Job) agendado rodando: ingestão → dbt run → dbt test,
  em sequência, com alerta em caso de falha.
- README com diagrama de arquitetura atualizado.

**Perguntas para o mentor:**
- Como ele estrutura CI/CD para dbt (dbt Cloud, GitHub Actions, Databricks
  Asset Bundles)?

---

## Semana 7 — Power BI + RLS

**Objetivo:** conectar o Power BI direto na camada gold do Databricks e montar
um dashboard com controle de acesso por usuário (Row-Level Security).

**Entregáveis:**
- Conexão Power BI → Databricks SQL Warehouse (via connector nativo).
- Dashboard com pelo menos: visão geral de corridas, receita por zona,
  sazonalidade, e uma página de qualidade de dados.
- RLS configurado (ex: um usuário só vê dados de determinado borough/zona).

**Perguntas para o mentor:**
- RLS estático vs dinâmico (tabela de mapeamento usuário → zona) — qual o
  padrão de mercado.

---

## Semana 8 — Polimento + Case de portfólio

**Objetivo:** transformar o projeto técnico em uma história contável para
entrevistas e LinkedIn.

**Entregáveis:**
- README final revisado, com prints do dashboard e do lineage do dbt.
- Post/case curto explicando decisões de arquitetura (por que medalhão, por
  que essas escolhas de modelagem, o que você aprenderia diferente hoje).
- Retro com o mentor: pontos fortes, gaps, e sugestão de próximo projeto
  (ex: streaming, CI/CD mais robusto, Unity Catalog, testes automatizados
  mais avançados com `dbt unit tests`).

---

## Backlog de "ir além" (se sobrar tempo)

- Unity Catalog e governança de dados.
- CI/CD com GitHub Actions rodando `dbt build` em PRs.
- `dbt unit tests` (testes unitários de lógica SQL).
- Streaming incremental com Auto Loader do Databricks.
- Segundo projeto com Snowflake + dbt para comparar as duas stacks.
