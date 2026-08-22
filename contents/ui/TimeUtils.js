// SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

/**
 * Convertit des heures et minutes en minutes depuis minuit (0..1439).
 */
function toMinutes(hour, minute) {
    const h = Number(hour);
    const m = Number(minute);
    return (isNaN(h) ? 0 : h) * 60 + (isNaN(m) ? 0 : m);
}

/**
 * Formate des minutes depuis minuit au format "HH:mm".
 */
function formatMinutes(minutes) {
    const num = Number(minutes);
    const valid = isNaN(num) ? 0 : num;
    const normalized = (Math.round(valid) % 1440 + 1440) % 1440;
    const h = Math.floor(normalized / 60);
    const m = normalized % 60;
    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
}

/**
 * Table de correspondance de coordonnées pour les fuseaux horaires courants
 * (permet une détection hors-ligne instantanée sans appel réseau).
 */
const TIMEZONE_COORDINATES = {
    "Europe/Paris": {lat: 48.8566, lon: 2.3522},
    "Europe/London": {lat: 51.5074, lon: -0.1278},
    "Europe/Berlin": {lat: 52.5200, lon: 13.4050},
    "Europe/Madrid": {lat: 40.4168, lon: -3.7038},
    "Europe/Rome": {lat: 41.9028, lon: 12.4964},
    "Europe/Brussels": {lat: 50.8503, lon: 4.3517},
    "Europe/Amsterdam": {lat: 52.3676, lon: 4.9041},
    "Europe/Zurich": {lat: 47.3769, lon: 8.5417},
    "America/New_York": {lat: 40.7128, lon: -74.0060},
    "America/Chicago": {lat: 41.8781, lon: -87.6298},
    "America/Denver": {lat: 39.7392, lon: -104.9903},
    "America/Los_Angeles": {lat: 34.0522, lon: -118.2437},
    "America/Montreal": {lat: 45.5017, lon: -73.5673},
    "America/Toronto": {lat: 43.6532, lon: -79.3832},
    "America/Vancouver": {lat: 49.2827, lon: -123.1207},
    "America/Sao_Paulo": {lat: -23.5505, lon: -46.6333},
    "Asia/Tokyo": {lat: 35.6762, lon: 139.6503},
    "Asia/Shanghai": {lat: 31.2304, lon: 121.4737},
    "Asia/Hong_Kong": {lat: 22.3193, lon: 114.1694},
    "Asia/Singapore": {lat: 1.3521, lon: 103.8198},
    "Asia/Dubai": {lat: 25.2048, lon: 55.2708},
    "Australia/Sydney": {lat: -33.8688, lon: 151.2093},
    "Pacific/Auckland": {lat: -36.8485, lon: 174.7633}
};

/**
 * Retourne les coordonnées géographiques estimées selon le fuseau horaire du système.
 * Estime la longitude via le décalage UTC et détecte l'hémisphère sud en cas de repli.
 */
function getSystemCoordinates(date) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    let detectedTz = "";
    try {
        if (typeof Intl !== "undefined" && Intl.DateTimeFormat) {
            detectedTz = Intl.DateTimeFormat().resolvedOptions().timeZone || "";
            if (detectedTz && TIMEZONE_COORDINATES[detectedTz]) {
                return TIMEZONE_COORDINATES[detectedTz];
            }
        }
    } catch (e) {
        // Repli sur le calcul par décalage
    }

    // Approximation de la longitude : 360° en 1440 min (1° toutes les 4 min)
    const tzOffsetMinutes = -d.getTimezoneOffset();
    const approxLon = tzOffsetMinutes / 4.0;

    // Détection des fuseaux de l'hémisphère sud pour attribuer une latitude australe réaliste
    const southernPrefixes = [
        "Australia/",
        "Pacific/",
        "Antarctica/",
        "America/Argentina",
        "America/Santiago",
        "America/Sao_Paulo",
        "Africa/Johannesburg"
    ];
    const isSouthern = detectedTz && southernPrefixes.some((prefix) => detectedTz.startsWith(prefix));
    const approxLat = isSouthern ? -33.8688 : 48.8566;

    return {lat: approxLat, lon: approxLon};
}

/**
 * Calcule les horaires astronomiques du cycle solaire (Lever, Zénith, Coucher, Crépuscule)
 * via les algorithmes d'éphémérides NOAA standard.
 * Gère les années bissextiles, le calcul UTC (immunisé au DST) et les extrêmes polaires.
 */
function calculateSolarSchedule(date, lat, lon) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const latitude = (typeof lat === "number" && !isNaN(lat)) ? lat : 48.8566;
    const longitude = (typeof lon === "number" && !isNaN(lon)) ? lon : 2.3522;

    const rad = Math.PI / 180.0;
    const deg = 180.0 / Math.PI;

    // 1. Jour de l'année calculé en UTC pur (immunisé contre le décalage DST)
    const year = d.getFullYear();
    const startOfYearUtc = Date.UTC(year, 0, 1);
    const dateUtc = Date.UTC(year, d.getMonth(), d.getDate());
    const dayOfYear = Math.floor((dateUtc - startOfYearUtc) / 86400000) + 1;

    // 2. Année fractionnaire en radians avec prise en compte des années bissextiles
    const isLeap = (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
    const daysInYear = isLeap ? 366.0 : 365.0;
    const gamma = (2.0 * Math.PI / daysInYear) * (dayOfYear - 1 + ((d.getHours() - 12) / 24.0));

    // 3. Équation du temps NOAA (en minutes)
    const eqTime = 229.18 * (0.000075 + 0.001868 * Math.cos(gamma) - 0.032077 * Math.sin(gamma)
        - 0.014615 * Math.cos(2 * gamma) - 0.040849 * Math.sin(2 * gamma));

    // 4. Déclinaison solaire (en radians)
    const decl = 0.006918 - 0.399912 * Math.cos(gamma) + 0.070257 * Math.sin(gamma)
        - 0.006758 * Math.cos(2 * gamma) + 0.000907 * Math.sin(2 * gamma);

    // 5. Décalage horaire local par rapport à UTC (en minutes)
    const tzOffsetMinutes = -d.getTimezoneOffset();

    // 6. Midi solaire réel en minutes locales depuis minuit
    const solarNoonMinutes = 720.0 - 4.0 * longitude - eqTime + tzOffsetMinutes;

    /**
     * Calcule l'angle horaire pour un zénith donné et évalue les cas polaires :
     * - cosHA > 1.0 : Nuit polaire (le soleil ne se lève pas)
     * - cosHA < -1.0 : Soleil de minuit (le soleil ne se couche pas)
     */
    function evaluateHourAngle(zenithDeg) {
        const cosHA = (Math.cos(zenithDeg * rad) - Math.sin(latitude * rad) * Math.sin(decl)) /
            (Math.cos(latitude * rad) * Math.cos(decl));

        if (cosHA > 1.0) {
            return {status: "POLAR_NIGHT", ha: null};
        }
        if (cosHA < -1.0) {
            return {status: "MIDNIGHT_SUN", ha: null};
        }
        return {status: "NORMAL", ha: Math.acos(cosHA) * deg};
    }

    // 90.833° = Zénith standard de lever/coucher (réfraction 34' et demi-diamètre solaire 16')
    const sunriseEval = evaluateHourAngle(90.833);
    // 96.0° = Zénith du crépuscule civil
    const duskEval = evaluateHourAngle(96.0);

    let sunriseMin, sunsetMin, duskMin;

    if (sunriseEval.status === "POLAR_NIGHT") {
        // Nuit polaire : le soleil reste sous l'horizon
        if (duskEval.status === "NORMAL" && duskEval.ha !== null) {
            const halfTwilight = duskEval.ha * 4.0;
            sunriseMin = solarNoonMinutes - halfTwilight;
            sunsetMin = solarNoonMinutes + halfTwilight;
            duskMin = sunsetMin + 30.0;
        } else {
            sunriseMin = solarNoonMinutes - 60.0;
            sunsetMin = solarNoonMinutes + 60.0;
            duskMin = solarNoonMinutes + 120.0;
        }
    } else if (sunriseEval.status === "MIDNIGHT_SUN") {
        // Soleil de minuit : le soleil reste au-dessus de l'horizon
        sunriseMin = solarNoonMinutes - 360.0;
        sunsetMin = solarNoonMinutes + 360.0;
        duskMin = solarNoonMinutes + 540.0;
    } else {
        // Calcul standard du lever, coucher et crépuscule
        const haSunrise = sunriseEval.ha;
        sunriseMin = solarNoonMinutes - haSunrise * 4.0;
        sunsetMin = solarNoonMinutes + haSunrise * 4.0;

        if (duskEval.status === "NORMAL" && duskEval.ha !== null) {
            duskMin = solarNoonMinutes + duskEval.ha * 4.0;
        } else {
            duskMin = sunsetMin + 45.0;
        }
    }

    const norm = (m) => ((Math.round(m) % 1440) + 1440) % 1440;

    return {
        morning: norm(sunriseMin),
        noon: norm(solarNoonMinutes),
        evening: norm(sunsetMin),
        night: norm(duskMin)
    };
}

/**
 * Retourne les plages horaires effectives en minutes selon la configuration.
 */
function getEffectiveSchedule(date, cfg) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const c = cfg || {};
    if (c.AutoSchedule !== false) {
        const sysCoords = getSystemCoordinates(d);
        return calculateSolarSchedule(d, sysCoords.lat, sysCoords.lon);
    }

    return {
        morning: toMinutes(c.MorningHour !== undefined ? c.MorningHour : 6, c.MorningMinute !== undefined ? c.MorningMinute : 0),
        noon: toMinutes(c.NoonHour !== undefined ? c.NoonHour : 12, c.NoonMinute !== undefined ? c.NoonMinute : 0),
        evening: toMinutes(c.EveningHour !== undefined ? c.EveningHour : 18, c.EveningMinute !== undefined ? c.EveningMinute : 0),
        night: toMinutes(c.NightHour !== undefined ? c.NightHour : 22, c.NightMinute !== undefined ? c.NightMinute : 0)
    };
}

/**
 * Détermine la période active (morning, noon, evening, night) selon l'heure et la planification.
 */
function getCurrentPeriod(date, cfg) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const currentMinutes = toMinutes(d.getHours(), d.getMinutes());
    const schedule = getEffectiveSchedule(d, cfg);

    const morningMin = schedule.morning;
    const noonMin = schedule.noon;
    const eveningMin = schedule.evening;
    const nightMin = schedule.night;

    // Ordre chronologique standard
    if (nightMin > eveningMin && eveningMin > noonMin && noonMin > morningMin) {
        if (currentMinutes >= nightMin || currentMinutes < morningMin) {
            return "night";
        }
        if (currentMinutes >= eveningMin) {
            return "evening";
        }
        if (currentMinutes >= noonMin) {
            return "noon";
        }
        return "morning";
    }

    // Repli pour les configurations manuelles non triées
    const slots = [
        {name: "morning", start: morningMin},
        {name: "noon", start: noonMin},
        {name: "evening", start: eveningMin},
        {name: "night", start: nightMin}
    ].sort((a, b) => a.start - b.start);

    let activeSlot = slots[slots.length - 1].name;
    for (let i = 0; i < slots.length; ++i) {
        if (currentMinutes >= slots[i].start) {
            activeSlot = slots[i].name;
        }
    }
    return activeSlot;
}

/**
 * Convertit de manière robuste un chemin local en URL file:// valide (gestion des espaces, #, ?, [ ]).
 */
function toSafeFileUrl(rawPath) {
    if (!rawPath || typeof rawPath !== "string") {
        return "";
    }
    const trimmed = rawPath.trim();
    if (trimmed.length === 0) {
        return "";
    }

    if (trimmed.startsWith("qrc:/") || trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
        return trimmed;
    }

    let localPath = trimmed;
    if (trimmed.startsWith("file://")) {
        localPath = trimmed.substring(7);
        try {
            localPath = decodeURIComponent(localPath);
        } catch (e) {
            // Conserver tel quel en cas d'échec de décodage
        }
    }

    const absPath = localPath.startsWith("/") ? localPath : "/" + localPath;
    try {
        return "file://" + encodeURI(absPath).replace(/#/g, "%23").replace(/\?/g, "%3F").replace(/\[/g, "%5B").replace(/]/g, "%5D");
    } catch (e) {
        const safeSegments = absPath.split("/").map((seg) => encodeURIComponent(seg)).join("/");
        return "file://" + safeSegments;
    }
}

/**
 * Résout l'URL de l'image correspondant à la période demandée.
 */
function getImageForPeriod(period, cfg, resolveLocalUrl) {
    const c = cfg || {};
    const safeResolve = (typeof resolveLocalUrl === "function") ? resolveLocalUrl : ((p) => p);
    let customImage;
    let defaultFile;

    switch (period) {
        case "morning":
            customImage = c.MorningImage;
            defaultFile = "../images/matin.png";
            break;
        case "noon":
            customImage = c.NoonImage;
            defaultFile = "../images/midi.png";
            break;
        case "evening":
            customImage = c.EveningImage;
            defaultFile = "../images/soir.png";
            break;
        case "night":
        default:
            customImage = c.NightImage;
            defaultFile = "../images/nuit.png";
            break;
    }

    if (customImage && String(customImage).trim().length > 0) {
        return toSafeFileUrl(String(customImage));
    }

    return safeResolve(defaultFile);
}

/**
 * Retourne les minutes de début et de fin d'une période dans la planification.
 */
function getPeriodRange(period, schedule) {
    if (!schedule || typeof schedule !== "object") {
        return {start: 0, end: 0};
    }
    const morning = schedule.morning !== undefined ? schedule.morning : 360;
    const noon = schedule.noon !== undefined ? schedule.noon : 720;
    const evening = schedule.evening !== undefined ? schedule.evening : 1080;
    const night = schedule.night !== undefined ? schedule.night : 1320;

    switch (period) {
        case "morning":
            return {start: morning, end: noon};
        case "noon":
            return {start: noon, end: evening};
        case "evening":
            return {start: evening, end: night};
        case "night":
        default:
            return {start: night, end: morning};
    }
}

/**
 * Retourne le nom d'icône système Plasma adapté à la période.
 */
function getPeriodIcon(period) {
    switch (period) {
        case "morning":
            return "weather-sunset-up";
        case "noon":
            return "weather-clear";
        case "evening":
            return "weather-sunset-down";
        case "night":
            return "weather-clear-night";
        default:
            return "preferences-system-time";
    }
}

/**
 * Calcule le nombre exact de millisecondes restantes avant le prochain changement de période.
 */
function getMsUntilNextPeriod(date, cfg) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const schedule = getEffectiveSchedule(d, cfg);

    const currentMs = ((d.getHours() * 60 + d.getMinutes()) * 60 + d.getSeconds()) * 1000 + d.getMilliseconds();

    // Points de transition distincts en millisecondes depuis minuit
    const points = [
        schedule.morning * 60000,
        schedule.noon * 60000,
        schedule.evening * 60000,
        schedule.night * 60000
    ].sort((a, b) => a - b);

    // Recherche du prochain point de transition strictement futur
    for (let i = 0; i < points.length; ++i) {
        if (points[i] > currentMs) {
            return points[i] - currentMs;
        }
    }

    // Si toutes les transitions du jour sont passées, le prochain point est le premier de demain
    const msUntilMidnight = 86400000 - currentMs;
    return msUntilMidnight + points[0];
}


