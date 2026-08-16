# Dicionário de dados — NYC Yellow Taxi Trip Records

> **Atenção**: esta versão foi compilada a partir de conhecimento geral sobre o
> dataset, sem conseguir validar contra o PDF oficial mais recente (minha busca
> na internet está indisponível no momento). Antes de usar esses códigos em
> conclusões definitivas da sua análise, confirme contra o dicionário oficial em:
> https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page (procure o link
> "Data Dictionary - Yellow Trips" na página).

## Colunas

| Coluna | Descrição |
|---|---|
| `VendorID` | Código da empresa fornecedora do sistema de táxi (TPEP provider) que registrou a corrida — não é o motorista nem a empresa de táxi em si. |
| `tpep_pickup_datetime` | Data/hora em que o taxímetro foi ligado (início da corrida). |
| `tpep_dropoff_datetime` | Data/hora em que o taxímetro foi desligado (fim da corrida). |
| `passenger_count` | Número de passageiros — informado manualmente pelo motorista, pode vir nulo ou 0 (não 100% confiável). |
| `trip_distance` | Distância da corrida em milhas, medida pelo taxímetro. |
| `RatecodeID` | Código da tarifa final aplicada: 1 = padrão, 2 = JFK, 3 = Newark, 4 = Nassau/Westchester, 5 = negociada, 6 = corrida em grupo. |
| `store_and_fwd_flag` | Y/N — se o registro ficou guardado na memória do veículo antes de ser enviado (por falta de conexão no momento da corrida). |
| `PULocationID` / `DOLocationID` | ID da zona de embarque/desembarque — chave que se conecta com o `taxi_zone_lookup.csv` (263-265 zonas). |
| `payment_type` | Código do pagamento: 1 = cartão de crédito, 2 = dinheiro, 3 = sem cobrança, 4 = disputa, 5 = desconhecido, 6 = corrida anulada. |
| `fare_amount` | Tarifa base calculada pelo taxímetro (tempo + distância). |
| `extra` | Sobretaxas diversas (ex: horário de pico, período noturno). |
| `mta_tax` | Taxa fixa da MTA, geralmente $0.50. |
| `tip_amount` | Gorjeta — só preenchida automaticamente quando o pagamento é cartão; gorjeta em dinheiro **não** entra aqui. |
| `tolls_amount` | Valor de pedágios pagos na corrida. |
| `improvement_surcharge` | Sobretaxa fixa de melhoria, geralmente $0.30. |
| `total_amount` | Valor total cobrado ao passageiro (não inclui gorjeta em dinheiro). |
| `congestion_surcharge` | Sobretaxa de congestionamento (áreas específicas de Manhattan). |
| `Airport_fee` | Taxa fixa quando o embarque é em aeroporto (JFK/LaGuardia). |
| `_ingested_at` | **Coluna nossa** — adicionada no notebook de ingestão bronze, marca quando o dado foi processado. |
| `_source_file` | **Coluna nossa** — adicionada no notebook de ingestão bronze, indica de qual arquivo Parquet a linha veio. |

## Observação sobre chave primária

Este dataset **não tem uma coluna de ID de corrida nativa**. Por isso, na camada
silver (`stg_taxi_trips`), geramos uma surrogate key (`trip_id`) a partir da
combinação de `vendor_id + pickup_at + dropoff_at + pickup_location_id +
dropoff_location_id`, usando a macro `dbt_utils.generate_surrogate_key`.

## Fonte

Dataset público da NYC Taxi & Limousine Commission (TLC):
https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
