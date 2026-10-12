"""Verifica el polígono; opcionalmente comprueba el grafo servido sin mutarlo."""
import argparse
import json
import math
from pathlib import Path
from urllib.request import urlopen

POINTS = {
    'Chiclayo': (-79.835, -6.771),
    'Pimentel': (-79.935, -6.836),
    'Morrope': (-80.011, -6.54),
    'Illimo': (-79.852, -6.473),
    'Ferreñafe': (-79.787, -6.639),
    'Chongoyape': (-79.388, -6.639),
    'Oyotun': (-79.3, -6.848),
    'Mocupe': (-79.626, -6.985),
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url')
    args = parser.parse_args()
    feature = json.loads(Path(__file__).with_name('coverage.geojson').read_text(encoding='utf-8-sig'))
    ring = feature['geometry']['coordinates'][0]
    assert ring[0] == ring[-1], 'El polígono debe estar cerrado'
    west, south, east, north = feature['bbox']
    assert min(p[0] for p in ring) == west and max(p[0] for p in ring) == east
    assert min(p[1] for p in ring) == south and max(p[1] for p in ring) == north
    for name, (lng, lat) in POINTS.items():
        assert west < lng < east and south < lat < north, f'{name} fuera de cobertura'
        if args.base_url:
            url = args.base_url.rstrip('/') + f'/nearest/v1/driving/{lng},{lat}?number=1'
            with urlopen(url, timeout=15) as response:
                result = json.load(response)
            assert result['code'] == 'Ok' and result['waypoints'], f'{name}: sin carretera'
            distance = result['waypoints'][0]['distance']
            assert distance < 2000, f'{name}: carretera a {distance:.0f} m, revisar el grafo servido'
        print(f'OK: {name}')
    width = (east - west) * 111.32 * math.cos(math.radians((north + south) / 2))
    height = (north - south) * 111.32
    print(f'Recorte aproximado: {width:.1f} x {height:.1f} km = {width * height:.0f} km2')

if __name__ == '__main__':
    main()
