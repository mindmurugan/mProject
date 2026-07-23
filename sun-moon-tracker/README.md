# Sun & Moon Tracker

A static web app that shows the sun and moon's real-time position for your location.

## Features

- Current GPS location (with manual lat/lon entry fallback)
- Live clock, plus a date + time-of-day slider to preview any moment
- Map view with the sun/moon direction overlaid as rays from your location
- A 2D sky-dome chart (center = zenith, edge = horizon) plotting sun/moon by azimuth and altitude
- Sun angle, azimuth, sunrise/sunset, solar noon, twilight
- Moon angle, azimuth, moonrise/moonset, distance, phase name and illumination %

## Running

No build step required — it's plain HTML/CSS/JS. Serve the folder statically, e.g.:

```
python3 -m http.server 8080
```

then open `http://localhost:8080/`.

Map tiles come from OpenStreetMap and require internet access in the browser.
Sun/moon math is powered by the vendored [SunCalc](https://github.com/mourner/suncalc)
library; the map is powered by vendored [Leaflet](https://leafletjs.com/). Both are
included under `vendor/` with their original licenses.
