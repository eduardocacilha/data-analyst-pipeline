-- Camada silver: limpeza e padronização da bronze, sem regra de negócio pesada.
-- Grão: 1 linha = 1 corrida.

with source as (

    select * from {{ source('bronze', 'nyc_taxi_trips') }}

),

renamed as (

    select
        -- chaves / dimensões
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
      and tpep_dropoff_datetime > tpep_pickup_datetime   -- remove registros inconsistentes

)

select * from renamed
