# 1. Usar la imagen oficial de OSRM
FROM osrm/osrm-backend:latest

# 2. Crear y definir el directorio de trabajo
WORKDIR /data

# 3. Descargar el mapa usando el comando nativo de Docker (sin usar apt ni wget)
ADD http://download.geofabrik.de/south-america/peru-latest.osm.pbf /data/peru-latest.osm.pbf

# 4. Procesar y compilar el mapa para rutas de automóviles (perfil car.lua)
RUN osrm-extract -p /opt/car.lua peru-latest.osm.pbf
RUN osrm-partition peru-latest.osrm
RUN osrm-customize peru-latest.osrm

# 5. Exponer el puerto interno del contenedor
EXPOSE 5000

# 6. Comando para arrancar el servidor con el mapa ya compilado
CMD ["osrm-routed", "--algorithm", "mld", "peru-latest.osrm"]