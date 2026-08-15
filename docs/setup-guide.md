# Guia de Setup — Contas e Ambiente

## 1. AWS (S3)

1. Criar conta em https://aws.amazon.com/free (free tier — 12 meses, 5GB S3
   grátis, mais que suficiente para este projeto).
2. **Nunca usar a conta root no dia a dia.** Criar um usuário IAM:
   - IAM → Users → Create user → nome ex. `analytics-engineer-project`.
   - Anexar uma policy customizada com permissão apenas no bucket do projeto
     (`s3:GetObject`, `s3:PutObject`, `s3:ListBucket`), nunca `AdministratorAccess`.
   - Gerar Access Key + Secret Key para esse usuário (guardar em local seguro,
     nunca commitar no Git).
3. Criar o bucket S3, ex: `s3://<seu-nome>-nyc-taxi-pipeline/`.
   - Dentro dele, criar os prefixos: `raw/`, `bronze/` (opcional, se preferir
     manter bronze também fora do Databricks), pode deixar silver/gold só
     dentro do Databricks/Delta.
4. Ativar "Block all public access" (o bucket é privado — o acesso é feito
   via chaves IAM, não público).

**Status neste projeto:** bucket `eduardo-personal-data-projects` já criado
na região `us-east-2` (Ohio), com os prefixos `raw/` e `bronze/`.

## Credenciais locais (.env)

Nunca commitar credenciais no Git. Este repositório já tem um `.env.example`
na raiz com o formato esperado (`.env` real está no `.gitignore`).

1. Copie o arquivo:
   ```bash
   cp .env.example .env
   ```
2. Abra o `.env` num editor de texto (não precisa ser por aqui) e preencha
   com a Access Key + Secret Key geradas para o usuário IAM
   `analytics-engineer-project` (Security credentials → Create access key).
3. O script `scripts/ingest_to_s3.py` e o dbt (via `python-dotenv`/variáveis
   de ambiente) vão ler essas variáveis automaticamente.

## 2. Databricks

**Opção A — Community Edition (gratuito, permanente)**
1. Criar conta em https://community.cloud.databricks.com/
2. Limitações a saber: sem Unity Catalog, sem acesso nativo a instance
   profiles do S3 — a leitura do S3 precisa ser feita via `boto3`/`requests`
   dentro do notebook usando as chaves IAM do usuário criado acima (ou usando
   endpoints públicos, se o bucket for público).
3. Criar um cluster single-node (runtime mais recente com Delta Lake).

**Opção B — Trial de 14 dias (Databricks na AWS)**
1. Criar em https://www.databricks.com/try-databricks — permite integrar a
   conta AWS de verdade, com Unity Catalog e external locations apontando
   pro S3 diretamente (mais parecido com produção, mas expira em 14 dias).

> Recomendação: comece pela Community Edition nas primeiras semanas (setup
> mais simples) e, se quiser experimentar Unity Catalog/external location de
> verdade, ative o trial mais perto da Semana 6 (orquestração), quando isso
> faz mais diferença.

## 3. dbt

```bash
python -m venv .venv
source .venv/bin/activate   # no Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

Depois, configurar `~/.dbt/profiles.yml` (fora do repositório, nunca commitar
credenciais):

```yaml
nyc_taxi_analytics:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: hive_metastore   # ou o catálogo do Unity Catalog, se estiver usando trial
      schema: dev_<seu_nome>
      host: <workspace-url>.cloud.databricks.com
      http_path: /sql/1.0/warehouses/<warehouse-id>   # ou http_path do cluster
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
      threads: 4
```

Gerar o token em: Databricks → User Settings → Developer → Access Tokens.
Guardar como variável de ambiente, nunca em texto puro:

```bash
export DBT_DATABRICKS_TOKEN="dapiXXXXXXXX"
```

Validar a conexão:

```bash
cd dbt/nyc_taxi_analytics
dbt debug
```

## 4. Power BI

1. Instalar o Power BI Desktop (gratuito).
2. Get Data → Databricks (connector nativo) → informar host + http_path do
   SQL Warehouse + token (mesmo do dbt).
3. Conectar direto na camada gold (schema `gold` ou `marts`, dependendo de
   como você nomear no dbt).

## Checklist rápido

- [ ] Conta AWS + usuário IAM com permissão restrita ao bucket
- [ ] Bucket S3 criado
- [ ] Conta Databricks criada (Community Edition ou trial)
- [ ] Cluster/warehouse ativo
- [ ] dbt instalado e `dbt debug` passando
- [ ] Power BI Desktop instalado
