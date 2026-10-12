# Chiclayo y alrededores

Cobertura propuesta basada en los mapas de reparto: Chiclayo, José Leonardo Ortiz, La Victoria, Pimentel, San José, Santa Rosa, Monsefú, Eten, Reque, Lambayeque, Mórrope, Mochumí, Túcume, Íllimo, Ferreñafe, Pítipo, Tumán, Pátapo, Pucalá, Pampa Grande, Chongoyape, Zaña, Cayaltí, Nueva Arica, Oyotún y Mocupe. Incluye margen hacia Maychil y Nanchoc; no representa el límite administrativo de Lambayeque.

`coverage.geojson` es la única definición del recorte usada por Docker: oeste -80.18, sur -7.12, este -79.08, norte -6.28. Aproximadamente 121 × 93 km, unos 11 350 km². Esto es extensión geográfica, no una estimación de RAM. El centro inicial del frontend es Chiclayo (-79.835, -6.771), no la ubicación exacta de la planta.

## Recursos

El build descarga Perú de Geofabrik, renumera los IDs para reducir los índices dispersos de extracción, recorta la región completando restricciones de giro y filtra vías, nodos viales y ferris. OSRM procesa únicamente esa región. La imagen final contiene solo el grafo: no contiene el PBF de Perú ni herramientas de extracción.

La extracción, partición y personalización suceden al construir la imagen, no al arrancar ni en cada consulta. OSRM usa MLD, dos hilos en el build y `OSRM_THREADS=2` en ejecución (puede reducirse a 1). Respeta `PORT` de Railway. El perfil car.lua corresponde a circulación por carreteras; no es un perfil específico de moto.

No hay medición de RAM todavía: este equipo no tiene Docker. El consumo depende de la cantidad de vías y del grafo, no solo del área. Los logs imprimen los objetos y bytes del extracto (`osmium fileinfo`) y el tamaño de los archivos OSRM (`du`). Medir antes de establecer límites estrictos de memoria.

## Verificación al construir/desplegar

```sh
docker build --progress=plain -t delparamo-osrm:chiclayo .
docker run --name delparamo-osrm-check --rm -p 5000:5000 -e OSRM_THREADS=2 delparamo-osrm:chiclayo
# En otra terminal:
python verify_coverage.py
python verify_coverage.py --base-url http://localhost:5000
docker stats --no-stream delparamo-osrm-check
```

La comprobación live exige que `/nearest` encuentre una calle a menos de 2 km en cada localidad de control. Si regresa una carretera de Iquitos a cientos de kilómetros, todavía está sirviendo el grafo anterior. Comprobar también `/route` y `/match` con recorridos reales después del cambio.

El backend de Del Páramo ya usa la URL del servicio OSRM de Railway. No se necesitan cambios en la app móvil para este mapa; hay que desplegar frontend y OSRM. Subir una rama no cambia la zona activa de Railway: integrar/desplegar solo después de revisar la construcción.

Fuentes: https://docs.osmcode.org/osmium/latest/osmium-extract.html ; https://docs.osmcode.org/osmium/latest/osmium-renumber.html ; https://github.com/Project-OSRM/osrm-backend
