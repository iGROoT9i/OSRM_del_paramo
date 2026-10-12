# El mapa nacional solo se utiliza al construir; no se incluye en el servicio final.
FROM debian:bookworm-slim AS map-extract
RUN apt-get update && apt-get install -y --no-install-recommends osmium-tool wget ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /data
COPY coverage.geojson /data/coverage.geojson
RUN wget -q --https-only https://download.geofabrik.de/south-america/peru-latest.osm.pbf -O peru.osm.pbf && \
    osmium renumber peru.osm.pbf -o peru-dense.osm.pbf && \
    osmium extract -s smart -S types=restriction -p coverage.geojson peru-dense.osm.pbf -o region.osm.pbf && \
    osmium tags-filter region.osm.pbf nw/highway r/type=restriction w/route=ferry -o chiclayo.osm.pbf && \
    osmium check-refs chiclayo.osm.pbf && \
    osmium fileinfo -e chiclayo.osm.pbf && \
    rm peru.osm.pbf peru-dense.osm.pbf region.osm.pbf

FROM ghcr.io/project-osrm/osrm-backend:v26.10.0-debian AS routing-build
WORKDIR /data
COPY --from=map-extract /data/chiclayo.osm.pbf /data/chiclayo.osm.pbf
RUN osrm-extract --threads 2 -p /opt/car.lua chiclayo.osm.pbf && \
    osrm-partition --threads 2 chiclayo.osrm && \
    osrm-customize --threads 2 chiclayo.osrm && \
    rm chiclayo.osm.pbf && du -sh /data

FROM ghcr.io/project-osrm/osrm-backend:v26.10.0-debian
WORKDIR /data
COPY --from=routing-build /data/ /data/
ENV OSRM_THREADS=2
EXPOSE 5000
CMD ["sh", "-c", "exec osrm-routed --algorithm mld --threads ${OSRM_THREADS} --port ${PORT:-5000} /data/chiclayo.osrm"]
