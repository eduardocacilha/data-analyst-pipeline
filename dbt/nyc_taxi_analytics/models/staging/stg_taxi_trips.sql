-- Camada silver: limpeza e padronização da bronze, sem regra de negócio pesada.
-- Grão: 1 linha = 1 corrida.
--
-- Observação importante: o dataset da NYC TLC NÃO tem um ID de corrida nativo.
-- Por isso geramos uma surrogate key (trip_id) a partir da combinação de colunas
-- que, juntas, tornam a linha praticamente única (vendor + timestamps + zonas).

with source as (

    select * from {{ source('bronze', 'nyc_taxi_trips') }}

),

renamed as (

    select
        -- chave substituta (surrogate key) - o dataset não tem ID de corrida nativo
        {{ dbt_utils.generate_surrogate_key([
            'vendorid',
            'tpep_pickup_datetime',
            'tpep_dropoff_datetime',
            'pulocationid',
            'dolocationid'
        ]) }} as trip_id,

        -- chaves / dimensões
        vendorid                    as vendor_id,
        pulocationid                as pickup_location_id,
        dolocationid                as dropoff_location_id,
        payment_type                as payment_type_id,

        -- tempo
        tpep_pickup_datetime        as pickup_at,
        tpep_dropoff_datetime       as dropoff_at,

        -- métricas
        passenger_count             as passenger_count,
        trip_distance                as trip_distance_miles,
        fare_amount                  as fare_amount,
        tip_amount                   as tip_amount,
        total_amount                 as total_amount,

        -- metadados técnicos (vindos da bronze)
        _ingested_at,
        _source_file

    from source
    where tpep_pickup_datetime is not null
      and tpep_dropoff_datetime is not null
      and tpep_dropoff_datetime > tpep_pickup_datetime
      and tpep_dropoff_datetime <= tpep_pickup_datetime + INTERVAL 3 HOURS
      and dolocationid is not null
      and payment_type is not null
      and passenger_count is not null
      and trip_distance is not null)   




