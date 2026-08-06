# Etapa 1: Descargar y recortar el mapa usando una imagen moderna
FROM debian:bullseye-slim AS builder

# Instalar wget y osmium-tool
RUN apt-get update && \
    apt-get install -y osmium-tool wget && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /data

# Descargar el mapa de Perú
RUN wget -q http://download.geofabrik.de/south-america/peru-latest.osm.pbf -O peru-latest.osm.pbf

# Recortar el mapa a la zona de Iquitos
RUN osmium extract -b -73.5,-4.0,-73.0,-3.5 peru-latest.osm.pbf -o iquitos.osm.pbf

# Etapa 2: Procesar y servir con OSRM
FROM osrm/osrm-backend:latest

WORKDIR /data

# Copiar solo el mapa pequeño de Iquitos desde la etapa 1
COPY --from=builder /data/iquitos.osm.pbf /data/iquitos.osm.pbf

# Compilar los datos de enrutamiento
RUN osrm-extract -p /opt/car.lua iquitos.osm.pbf && \
    osrm-partition iquitos.osrm && \
    osrm-customize iquitos.osrm && \
    rm iquitos.osm.pbf

EXPOSE 5000

# Arrancar el servidor
CMD ["osrm-routed", "--algorithm", "mld", "iquitos.osrm"]