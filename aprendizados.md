# Learn Control — Analytics Engineering (Semana 1-2)

Documento de autoavaliação, compilado a partir da jornada de construção deste
projeto. Objetivo: você levar consigo (inclusive pra outra máquina) uma visão
honesta de onde está forte e onde vale investir energia deliberada daqui pra
frente — não é elogio nem crítica gratuita, é um mapa de aprendizado.

---

## Pontos fortes observados

**1. Postura de aprendizado genuína, não só "fazer funcionar"**
Você recusou código pronto várias vezes de propósito ("não quero código
pronto, quero ideias"), pediu pra entender o *porquê* antes de aceitar uma
solução, e questionou lógica antes de rodar (ex: desconfiou do `datediff`,
perguntou se o `;` quebraria o dbt antes de simplesmente aceitar). Isso é
exatamente o oposto do padrão "copiar e colar sem entender" — é a diferença
entre quem sabe *usar* uma ferramenta e quem sabe *raciocinar* sobre o
problema.

**2. Você já debugou sozinho, mais de uma vez**
Fechou o filtro quebrado do `stg_taxi_trips.sql` (aquele `and` sem predicado),
corrigiu a referência errada no WHERE (`dropoff_location_id` → `dolocationid`)
depois de entender o motivo, e adicionou a linha final que faltava (`select *
from renamed`) — tudo isso sem eu escrever o código, só com a explicação do
problema. Esse é o comportamento que separa quem "sabe pedir ajuda direito"
de quem fica dependente.

**3. Entendimento conceitual da arquitetura medalhão é sólido**
Você não só entendeu bronze/silver/gold, como desenhou seu próprio diagrama,
identificou uma camada extra ("silver de contexto") por conta própria, e
depois de uma explicação, conseguiu mapear isso pro vocabulário padrão do
mercado (`intermediate`, no dbt) sem se apegar ao termo errado. E já validou
esse entendimento externamente — apresentou pro seu mentor e disse que foi
"tranquilo de se virar".

**4. Disciplina de investigação técnica**
Em vários momentos de erro (autenticação do dbt, push do Git, Git folder
vazio, teste de unicidade falhando), você trouxe o print/output completo,
sem economizar detalhe — isso é o que permite debugar rápido. Muita gente
trava justamente porque não sabe "mostrar o problema" direito.

**5. Curiosidade que vai além do roteiro**
Perguntou sobre hash nativo do Databricks, sobre Databricks Git folders,
sobre DBeaver — você foi atrás de alternativas e ferramentas por conta
própria, não só seguiu o script.

---

## Pontos de atenção / onde vale investir energia

**1. Fundamentos de terminal e ambiente operacional**
Boa parte do atrito não foi "engenharia de dados" de verdade, foi ambiente:
diferença entre CMD e PowerShell, variáveis de ambiente (PATH, tokens),
diferença entre `.env` e `.env.example`, rodar comando na pasta errada
(aconteceu **duas vezes** com o `dbt_project.yml`). Isso é normal pra quem
vem de um caminho mais analista/BI e está migrando pra engenharia, mas é
uma fundação que vale reforçar deliberadamente — não é conhecimento de
"analytics engineering" em si, é conhecimento de "desenvolvedor" de base,
e ele acelera tudo o resto.
> Sugestão prática: sempre que abrir um terminal novo pra trabalhar no
> projeto, rode `pwd` (ou `cd` sem argumento no Windows) como reflexo antes
> de rodar qualquer comando de projeto (`dbt`, `git`).

**2. Ordem lógica de execução de uma query SQL**
O bug do alias no WHERE (`dropoff_location_id is not null` antes dele
existir) é um erro clássico de quem ainda não internalizou completamente a
ordem real de processamento de uma query (`FROM` → `WHERE` → `SELECT` →
...). Você entendeu a explicação rápido, mas vale fazer alguns exercícios
deliberados só sobre isso — é a base de tudo em SQL avançado (window
functions, CTEs aninhadas, etc dependem dessa intuição).

**3. Modelo mental de "onde cada coisa vive" ainda em formação**
Você mesmo verbalizou isso ("nem consigo localizar essa automação", "não
entendi muito bem como todo o pipeline funciona") — e teve pelo menos dois
episódios concretos de perder o controle de "qual versão está onde"
(notebook duplicado dentro/fora do Git folder; dúvida se commit no
Databricks reflete no local). Isso é natural num projeto que atravessa
4 sistemas diferentes (sua máquina, GitHub, Databricks, S3) mas é o próximo
músculo a desenvolver: antes de editar qualquer arquivo, se perguntar "esse
arquivo está rastreado por git? em qual repositório/pasta ele realmente
está?".

**4. Qualidade de dado além do "não é nulo"**
Seu primeiro instinto de filtro foi certeiro (nulos, duração implausível),
mas o teste de unicidade da `trip_id` revelou 139.988 colisões — um sinal de
que "criar uma chave" e "validar que ela é única de verdade" são dois passos
diferentes, e o segundo exige investigação (comparar linhas duplicadas,
entender se é coincidência ou duplicata real). Essa investigação ainda está
em aberto no projeto — é uma ótima oportunidade de praticar esse músculo.

---

## O que você já sabe fazer, de fato (não é teoria, é prática validada)

- Criar e configurar usuário IAM com permissão restrita na AWS.
- Subir dado pro S3 via script Python com boto3.
- Criar tabela Delta no Databricks a partir de dado externo (bronze).
- Guardar credenciais com segurança usando secret scope do Databricks.
- Configurar o dbt-databricks do zero (profiles.yml, variável de ambiente
  de token, `dbt debug`).
- Escrever um model dbt com CTEs, source/ref, e identificar/corrigir erros
  de sintaxe reais.
- Criar e interpretar testes de dados (`not_null`, `unique`) via dbt.
- Resolver a ausência de chave primária natural com surrogate key
  (`dbt_utils.generate_surrogate_key`).
- Configurar Git do zero (init, remote, autenticação HTTPS, branch), e
  sincronizar um workspace externo (Databricks) com GitHub via Git folders.
- Fazer troubleshooting sistemático (ler stack trace, isolar variável,
  testar hipótese por vez).

## Onde o projeto está agora (pra retomar na outra máquina)

- **Raw (S3)**: 4 meses de dado (jan-abr/2024) ✅
- **Bronze (Databricks)**: `workspace.bronze.nyc_taxi_trips`, 13M linhas ✅
- **Silver (dbt)**: `stg_taxi_trips` rodando, com `trip_id` (surrogate key)
  — mas com um problema de qualidade em aberto: 139.988 valores duplicados
  de `trip_id`, ainda não investigado a fundo (ver `docs/pipeline_overview.md`
  pra mais contexto).
- **Intermediate**: não iniciado.
- **Gold**: só esqueleto (`fct_trips.sql`, `dim_zone.sql`).
- **Power BI**: não iniciado, mas já mapeado como conectar quando a gold
  estiver pronta.

## Próximos passos sugeridos (em ordem)

1. Investigar as duplicatas de `trip_id` (comparar linhas na bronze pra
   entender se é coincidência de chave ou duplicata real de dado).
2. Decidir e implementar a solução para o problema de unicidade.
3. Completar o seed `taxi_zone_lookup.csv` com as 265 zonas reais.
4. Construir `int_trips_enriched.sql` (camada intermediate).
5. Atualizar `fct_trips.sql` e `dim_zone.sql` pra consumir do intermediate.
6. Conectar e montar o primeiro dashboard no Power BI.

---

*Documento gerado como parte da mentoria/autoestudo em Analytics Engineering,
referente às primeiras semanas do projeto NYC Taxi Pipeline.*
