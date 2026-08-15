-- TODO (Semana 5): dimensão de zonas, a partir do seed taxi_zone_lookup.
-- Grão: 1 linha por LocationID.

select
    locationid   as zone_id,
    borough,
    zone         as zone_name,
    service_zone

from {{ ref('taxi_zone_lookup') }}
