(function () {
  'use strict';

  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------

  var state = {
    lat: 40.7128,
    lon: -74.0060,
    hasRealLocation: false,
    live: true
  };

  var DEFAULT_LOCATION_NOTE = 'Location unavailable — showing default (New York). Use Manual to set your own.';

  // ---------------------------------------------------------------------
  // DOM references
  // ---------------------------------------------------------------------

  var el = {
    locationValue: document.getElementById('location-value'),
    timeValue: document.getElementById('time-value'),
    tzValue: document.getElementById('tz-value'),
    gpsBtn: document.getElementById('gps-btn'),
    manualBtn: document.getElementById('manual-btn'),
    manualPanel: document.getElementById('manual-panel'),
    latInput: document.getElementById('lat-input'),
    lonInput: document.getElementById('lon-input'),
    manualApply: document.getElementById('manual-apply'),
    dateInput: document.getElementById('date-input'),
    timeSlider: document.getElementById('time-slider'),
    sliderReadout: document.getElementById('slider-time-readout'),
    nowBtn: document.getElementById('now-btn'),
    sky: document.getElementById('sky-diagram'),
    sunAltitude: document.getElementById('sun-altitude'),
    sunAzimuth: document.getElementById('sun-azimuth'),
    moonAltitude: document.getElementById('moon-altitude'),
    moonAzimuth: document.getElementById('moon-azimuth'),
    sunrise: document.getElementById('sunrise'),
    sunset: document.getElementById('sunset'),
    daylength: document.getElementById('daylength'),
    solarNoon: document.getElementById('solar-noon'),
    twilight: document.getElementById('twilight'),
    moonrise: document.getElementById('moonrise'),
    moonset: document.getElementById('moonset'),
    moonDistance: document.getElementById('moon-distance'),
    moonPhaseName: document.getElementById('moon-phase-name'),
    moonIllumination: document.getElementById('moon-illumination')
  };

  // ---------------------------------------------------------------------
  // Small geo / math helpers
  // ---------------------------------------------------------------------

  var DEG = 180 / Math.PI;

  function toBearing(azimuthRad) {
    // SunCalc azimuth: radians, 0 = south, positive clockwise towards west.
    // Convert to standard compass bearing: 0 = north, clockwise.
    return (azimuthRad * DEG + 180 + 360) % 360;
  }

  function destinationPoint(lat, lon, bearingDeg, distKm) {
    var R = 6371;
    var delta = distKm / R;
    var theta = bearingDeg * Math.PI / 180;
    var phi1 = lat * Math.PI / 180;
    var lambda1 = lon * Math.PI / 180;

    var phi2 = Math.asin(
      Math.sin(phi1) * Math.cos(delta) + Math.cos(phi1) * Math.sin(delta) * Math.cos(theta)
    );
    var lambda2 = lambda1 + Math.atan2(
      Math.sin(theta) * Math.sin(delta) * Math.cos(phi1),
      Math.cos(delta) - Math.sin(phi1) * Math.sin(phi2)
    );

    return [phi2 * DEG, ((lambda2 * DEG) + 540) % 360 - 180];
  }

  function pad(n) { return n < 10 ? '0' + n : '' + n; }

  function fmtTime(date) {
    if (!date || isNaN(date.getTime())) return '—';
    return pad(date.getHours()) + ':' + pad(date.getMinutes());
  }

  function fmtDeg(n) {
    if (n === null || n === undefined || isNaN(n)) return '--°';
    return (n >= 0 ? '+' : '') + n.toFixed(1) + '°';
  }

  function moonPhaseName(t) {
    var names = [
      'New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous',
      'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent'
    ];
    var idx = Math.round(t * 8) % 8;
    return names[idx];
  }

  // ---------------------------------------------------------------------
  // Date/time control
  // ---------------------------------------------------------------------

  function ymd(date) {
    return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate());
  }

  function minutesOfDay(date) {
    return date.getHours() * 60 + date.getMinutes();
  }

  function syncControlsToDate(date) {
    el.dateInput.value = ymd(date);
    el.timeSlider.value = minutesOfDay(date);
    el.sliderReadout.textContent = pad(date.getHours()) + ':' + pad(date.getMinutes());
  }

  function getEffectiveDate() {
    if (state.live) return new Date();

    var parts = el.dateInput.value.split('-').map(Number);
    var minutes = Number(el.timeSlider.value);
    var d = new Date(parts[0], (parts[1] || 1) - 1, parts[2] || 1);
    d.setHours(Math.floor(minutes / 60), minutes % 60, 0, 0);
    return d;
  }

  function enterPreviewMode() {
    if (state.live) {
      state.live = false;
      el.nowBtn.classList.add('primary');
    }
  }

  el.dateInput.addEventListener('input', function () {
    enterPreviewMode();
    update();
  });

  el.timeSlider.addEventListener('input', function () {
    enterPreviewMode();
    var minutes = Number(el.timeSlider.value);
    el.sliderReadout.textContent = pad(Math.floor(minutes / 60)) + ':' + pad(minutes % 60);
    update();
  });

  el.nowBtn.addEventListener('click', function () {
    state.live = true;
    syncControlsToDate(new Date());
    update();
  });

  // ---------------------------------------------------------------------
  // Location handling
  // ---------------------------------------------------------------------

  function setLocationText(text) {
    el.locationValue.textContent = text;
  }

  function applyLocation(lat, lon, real) {
    state.lat = lat;
    state.lon = lon;
    state.hasRealLocation = !!real;
    el.latInput.value = lat.toFixed(4);
    el.lonInput.value = lon.toFixed(4);
    setLocationText(lat.toFixed(4) + '°, ' + lon.toFixed(4) + '°' + (real ? '' : ' (default)'));
    map.setView([lat, lon], map.getZoom() < 6 ? 11 : map.getZoom());
    update();
  }

  function requestGPS() {
    if (!('geolocation' in navigator)) {
      setLocationText(DEFAULT_LOCATION_NOTE);
      el.manualPanel.hidden = false;
      applyLocation(state.lat, state.lon, false);
      return;
    }
    setLocationText('Detecting…');
    navigator.geolocation.getCurrentPosition(
      function (pos) {
        applyLocation(pos.coords.latitude, pos.coords.longitude, true);
      },
      function () {
        setLocationText(DEFAULT_LOCATION_NOTE);
        el.manualPanel.hidden = false;
        applyLocation(state.lat, state.lon, false);
      },
      { enableHighAccuracy: true, timeout: 8000, maximumAge: 60000 }
    );
  }

  el.gpsBtn.addEventListener('click', requestGPS);

  el.manualBtn.addEventListener('click', function () {
    el.manualPanel.hidden = !el.manualPanel.hidden;
  });

  el.manualApply.addEventListener('click', function () {
    var lat = parseFloat(el.latInput.value);
    var lon = parseFloat(el.lonInput.value);
    if (isNaN(lat) || isNaN(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      window.alert('Please enter a valid latitude (-90 to 90) and longitude (-180 to 180).');
      return;
    }
    applyLocation(lat, lon, true);
    el.manualPanel.hidden = true;
  });

  // ---------------------------------------------------------------------
  // Map
  // ---------------------------------------------------------------------

  var map = L.map('map', { zoomControl: true }).setView([state.lat, state.lon], 4);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 18,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  var youIcon = L.divIcon({ className: '', html: '<div class="you-marker"></div>', iconSize: [14, 14] });
  var sunIcon = L.divIcon({ className: '', html: '<div class="sun-marker">☀️</div>', iconSize: [26, 26] });
  var moonIcon = L.divIcon({ className: '', html: '<div class="moon-marker">🌙</div>', iconSize: [26, 26] });

  var youMarker = L.marker([state.lat, state.lon], { icon: youIcon }).addTo(map);
  var sunMarker = L.marker([state.lat, state.lon], { icon: sunIcon, opacity: 0 }).addTo(map);
  var moonMarker = L.marker([state.lat, state.lon], { icon: moonIcon, opacity: 0 }).addTo(map);

  var sunLine = L.polyline([[state.lat, state.lon], [state.lat, state.lon]], {
    color: '#ffb84d', weight: 2, dashArray: '6 6', opacity: 0.85
  }).addTo(map);

  var moonLine = L.polyline([[state.lat, state.lon], [state.lat, state.lon]], {
    color: '#a9b7d6', weight: 2, dashArray: '6 6', opacity: 0.85
  }).addTo(map);

  function rayDistanceKm() {
    try {
      var bounds = map.getBounds();
      var center = map.getCenter();
      var edge = bounds.getNorthEast();
      var distKm = center.distanceTo(edge) / 1000;
      return Math.max(distKm * 0.6, 0.05);
    } catch (e) {
      return 5;
    }
  }

  function updateMapRays(sunBearing, sunAltDeg, moonBearing, moonAltDeg) {
    var dist = rayDistanceKm();
    var origin = [state.lat, state.lon];

    youMarker.setLatLng(origin);

    var sunEnd = destinationPoint(state.lat, state.lon, sunBearing, dist);
    sunMarker.setLatLng(sunEnd);
    sunMarker.setOpacity(sunAltDeg >= 0 ? 1 : 0.35);
    sunLine.setLatLngs([origin, sunEnd]);
    sunLine.setStyle({ opacity: sunAltDeg >= 0 ? 0.85 : 0.3 });

    var moonEnd = destinationPoint(state.lat, state.lon, moonBearing, dist);
    moonMarker.setLatLng(moonEnd);
    moonMarker.setOpacity(moonAltDeg >= 0 ? 1 : 0.35);
    moonLine.setLatLngs([origin, moonEnd]);
    moonLine.setStyle({ opacity: moonAltDeg >= 0 ? 0.85 : 0.3 });
  }

  map.on('moveend zoomend', function () {
    if (window.__lastPositions) {
      updateMapRays.apply(null, window.__lastPositions);
    }
  });

  // ---------------------------------------------------------------------
  // Sky diagram (polar chart: center = zenith, edge = horizon)
  // ---------------------------------------------------------------------

  var SKY_NS = 'http://www.w3.org/2000/svg';
  var cx = 220, cy = 150, R = 95;

  function svgEl(tag, attrs) {
    var e = document.createElementNS(SKY_NS, tag);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    return e;
  }

  function polarPoint(bearingDeg, altDeg) {
    var r;
    if (altDeg >= 0) {
      r = R * (90 - altDeg) / 90;
    } else {
      var clamped = Math.max(altDeg, -30);
      r = R + (R * 0.35) * (-clamped / 30);
    }
    var theta = bearingDeg * Math.PI / 180;
    return [cx + r * Math.sin(theta), cy - r * Math.cos(theta), r];
  }

  function buildSkyStatic() {
    el.sky.innerHTML = '';

    // below-horizon boundary
    el.sky.appendChild(svgEl('circle', {
      cx: cx, cy: cy, r: R * 1.35, fill: 'none', stroke: '#1c2740', 'stroke-width': 1, 'stroke-dasharray': '3 4'
    }));

    // horizon circle
    el.sky.appendChild(svgEl('circle', {
      cx: cx, cy: cy, r: R, fill: 'rgba(255,255,255,0.02)', stroke: '#3a4870', 'stroke-width': 1.5
    }));

    // altitude rings at 30 / 60
    [30, 60].forEach(function (a) {
      var r = R * (90 - a) / 90;
      el.sky.appendChild(svgEl('circle', {
        cx: cx, cy: cy, r: r, fill: 'none', stroke: '#24304a', 'stroke-width': 1
      }));
    });

    // zenith marker
    el.sky.appendChild(svgEl('circle', { cx: cx, cy: cy, r: 2.5, fill: '#93a1bd' }));

    // compass labels
    var dirs = [
      ['N', 0], ['E', 90], ['S', 180], ['W', 270]
    ];
    dirs.forEach(function (d) {
      var p = polarPoint(d[1], -30);
      var text = svgEl('text', {
        x: p[0], y: p[1] + 4, 'text-anchor': 'middle',
        fill: '#93a1bd', 'font-size': '13', 'font-weight': '600'
      });
      text.textContent = d[0];
      el.sky.appendChild(text);
    });

    var horizonLabel = svgEl('text', {
      x: cx, y: cy + R + 16, 'text-anchor': 'middle', fill: '#4a5a80', 'font-size': '10'
    });
    horizonLabel.textContent = 'horizon';
    el.sky.appendChild(horizonLabel);
  }

  var sunGroup = null, moonGroup = null;

  function drawBody(bearingDeg, altDeg, symbol, colorClass, label) {
    var p = polarPoint(bearingDeg, altDeg);
    var g = svgEl('g', {});

    var line = svgEl('line', {
      x1: cx, y1: cy, x2: p[0], y2: p[1],
      stroke: colorClass === 'sun' ? '#ffb84d' : '#a9b7d6',
      'stroke-width': 1.4, 'stroke-dasharray': '4 4',
      opacity: altDeg >= 0 ? 0.8 : 0.35
    });
    g.appendChild(line);

    var marker = svgEl('text', {
      x: p[0], y: p[1] + 6, 'text-anchor': 'middle', 'font-size': '22',
      opacity: altDeg >= 0 ? 1 : 0.4
    });
    marker.textContent = symbol;
    g.appendChild(marker);

    var tag = svgEl('text', {
      x: p[0], y: p[1] + 22, 'text-anchor': 'middle', 'font-size': '10',
      fill: colorClass === 'sun' ? '#ffb84d' : '#a9b7d6', 'font-weight': '600'
    });
    tag.textContent = label + ' ' + (altDeg >= 0 ? '+' : '') + altDeg.toFixed(0) + '°';
    g.appendChild(tag);

    el.sky.appendChild(g);
  }

  function updateSkyBackground(sunAltDeg) {
    var bg;
    if (sunAltDeg > 10) bg = 'linear-gradient(#0f2350, #123a5e)';
    else if (sunAltDeg > -2) bg = 'linear-gradient(#3a2a4a, #7a4a3a)';
    else if (sunAltDeg > -10) bg = 'linear-gradient(#161a3a, #241d3f)';
    else bg = 'linear-gradient(#070b18, #0c1226)';
    el.sky.style.background = bg;
  }

  function drawSky(sunBearing, sunAltDeg, moonBearing, moonAltDeg) {
    buildSkyStatic();
    drawBody(sunBearing, sunAltDeg, '☀️', 'sun', 'Sun');
    drawBody(moonBearing, moonAltDeg, '🌙', 'moon', 'Moon');
    updateSkyBackground(sunAltDeg);
  }

  // ---------------------------------------------------------------------
  // Main update loop
  // ---------------------------------------------------------------------

  function update() {
    var date = getEffectiveDate();

    el.timeValue.textContent = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) +
      (state.live ? '' : ' (preview)');

    var sunPos = SunCalc.getPosition(date, state.lat, state.lon);
    var moonPos = SunCalc.getMoonPosition(date, state.lat, state.lon);
    var moonIllum = SunCalc.getMoonIllumination(date);
    var sunTimes = SunCalc.getTimes(date, state.lat, state.lon);
    var moonTimes = SunCalc.getMoonTimes(date, state.lat, state.lon, false);

    var sunAltDeg = sunPos.altitude * DEG;
    var sunBearing = toBearing(sunPos.azimuth);
    var moonAltDeg = moonPos.altitude * DEG;
    var moonBearing = toBearing(moonPos.azimuth);

    // Details: sun
    el.sunAltitude.textContent = fmtDeg(sunAltDeg);
    el.sunAzimuth.textContent = 'Azimuth ' + sunBearing.toFixed(1) + '°';

    el.moonAltitude.textContent = fmtDeg(moonAltDeg);
    el.moonAzimuth.textContent = 'Azimuth ' + moonBearing.toFixed(1) + '°';

    el.sunrise.textContent = fmtTime(sunTimes.sunrise);
    el.sunset.textContent = fmtTime(sunTimes.sunset);
    if (sunTimes.sunrise && sunTimes.sunset && !isNaN(sunTimes.sunrise) && !isNaN(sunTimes.sunset)) {
      var mins = Math.round((sunTimes.sunset - sunTimes.sunrise) / 60000);
      if (mins > 0) {
        el.daylength.textContent = 'Day length ' + Math.floor(mins / 60) + 'h ' + (mins % 60) + 'm';
      } else {
        el.daylength.textContent = '';
      }
    }

    el.solarNoon.textContent = fmtTime(sunTimes.solarNoon);
    el.twilight.textContent = 'Dawn ' + fmtTime(sunTimes.dawn) + ' · Dusk ' + fmtTime(sunTimes.dusk);

    if (moonTimes.alwaysUp) {
      el.moonrise.textContent = '—';
      el.moonset.textContent = '—';
      el.moonDistance.textContent = 'Moon up all day';
    } else if (moonTimes.alwaysDown) {
      el.moonrise.textContent = '—';
      el.moonset.textContent = '—';
      el.moonDistance.textContent = 'Moon down all day';
    } else {
      el.moonrise.textContent = fmtTime(moonTimes.rise);
      el.moonset.textContent = fmtTime(moonTimes.set);
      el.moonDistance.textContent = 'Distance ' + Math.round(moonPos.distance).toLocaleString() + ' km';
    }

    el.moonPhaseName.textContent = moonPhaseName(moonIllum.phase);
    el.moonIllumination.textContent = 'Illumination ' + Math.round(moonIllum.fraction * 100) + '%';

    updateMapRays(sunBearing, sunAltDeg, moonBearing, moonAltDeg);
    window.__lastPositions = [sunBearing, sunAltDeg, moonBearing, moonAltDeg];

    drawSky(sunBearing, sunAltDeg, moonBearing, moonAltDeg);
  }

  // ---------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------

  el.tzValue.textContent = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
  syncControlsToDate(new Date());
  applyLocation(state.lat, state.lon, false);
  requestGPS();

  setInterval(function () {
    if (state.live) {
      syncControlsToDate(new Date());
      update();
    }
  }, 1000);

  update();
})();
