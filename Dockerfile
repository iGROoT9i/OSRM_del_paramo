# 1. Usar la imagen oficial de OSRM
FROM osrm/osrm-backend:latest

# 2. Instalar dependencias para procesar el mapa
RUN apt-get update && \
    apt-get install -y osmium-tool && \
    rm -rf /var/lib/apt/lists/*

# 3. Crear y definir el directorio de trabajo
WORKDIR /data

# 4. Descargar el mapa de todo Perú
ADD http://download.geofabrik.de/south-america/peru-latest.osm.pbf /data/peru-latest.osm.pbf

# 5. Recortar el mapa SÓLO para la zona de Iquitos y procesar OSRM en la misma capa
# Bounding box para Iquitos y alrededores aprox: -73.5, -4.0, -73.0, -3.5 (min_lon, min_lat, max_lon, max_lat)
RUN osmium extract -b -73.5,-4.0,-73.0,-3.5 peru-latest.osm.pbf -o iquitos.osm.pbf && \
    rm peru-latest.osm.pbf && \
    osrm-extract -p /opt/car.lua iquitos.osm.pbf && \
    osrm-partition iquitos.osrm && \
    osrm-customize iquitos.osrm && \
    rm iquitos.osm.pbf

# 6. Exponer el puerto interno del contenedor
EXPOSE 5000

# 7. Comando para arrancar el servidor con el mapa optimizado de Iquitos
CMD ["osrm-routed", "--algorithm", "mld", "iquitos.osrm"]