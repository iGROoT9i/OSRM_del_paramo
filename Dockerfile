# 1. Usar la imagen oficial de OSRM
FROM osrm/osrm-backend:latest

# 2. Instalar wget para poder descargar el mapa de Perú
RUN apt-get update && apt-get install -y wget

# 3. Crear y definir el directorio de trabajo
WORKDIR /data

# 4. Descargar el mapa actualizado de Perú desde Geofabrik
RUN wget http://download.geofabrik.de/south-america/peru-latest.osm.pbf

# 5. Procesar y compilar el mapa para rutas de automóviles (perfil car.lua)
RUN osrm-extract -p /opt/car.lua peru-latest.osm.pbf
RUN osrm-partition peru-latest.osrm
RUN osrm-customize peru-latest.osrm

# 6. Exponer el puerto interno del contenedor
EXPOSE 5000

# 7. Comando para arrancar el servidor con el mapa ya compilado
CMD ["osrm-routed", "--algorithm", "mld", "peru-latest.osrm"]