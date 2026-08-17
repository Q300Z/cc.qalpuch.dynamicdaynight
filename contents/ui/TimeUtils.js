// SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

.pragma library

/**
 * Converts hours and minutes into minutes from the beginning of the day (0..1439).
 * @param {number} hour
 * @param {number} minute
 * @returns {number}
 */
function toMinutes(hour, minute) {
    const h = Number(hour);
    const m = Number(minute);
    return (isNaN(h) ? 0 : h) * 60 + (isNaN(m) ? 0 : m);
}

/**
 * Formats minutes from midnight into "HH:mm".
 * @param {number} minutes
 * @returns {string}
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
 * Approximate coordinates mapping for common system timezones
 * to provide instant, offline auto-detection without network calls.
 */
const TIMEZONE_COORDINATES = {
    "Europe/Paris": { lat: 48.8566, lon: 2.3522 },
    "Europe/London": { lat: 51.5074, lon: -0.1278 },
    "Europe/Berlin": { lat: 52.5200, lon: 13.4050 },
    "Europe/Madrid": { lat: 40.4168, lon: -3.7038 },
    "Europe/Rome": { lat: 41.9028, lon: 12.4964 },
    "Europe/Brussels": { lat: 50.8503, lon: 4.3517 },
    "Europe/Amsterdam": { lat: 52.3676, lon: 4.9041 },
    "Europe/Zurich": { lat: 47.3769, lon: 8.5417 },
    "America/New_York": { lat: 40.7128, lon: -74.0060 },
    "America/Chicago": { lat: 41.8781, lon: -87.6298 },
    "America/Denver": { lat: 39.7392, lon: -104.9903 },
    "America/Los_Angeles": { lat: 34.0522, lon: -118.2437 },
    "America/Montreal": { lat: 45.5017, lon: -73.5673 },
    "America/Toronto": { lat: 43.6532, lon: -79.3832 },
    "America/Vancouver": { lat: 49.2827, lon: -123.1207 },
    "America/Sao_Paulo": { lat: -23.5505, lon: -46.6333 },
    "Asia/Tokyo": { lat: 35.6762, lon: 139.6503 },
    "Asia/Shanghai": { lat: 31.2304, lon: 121.4737 },
    "Asia/Hong_Kong": { lat: 22.3193, lon: 114.1694 },
    "Asia/Singapore": { lat: 1.3521, lon: 103.8198 },
    "Asia/Dubai": { lat: 25.2048, lon: 55.2708 },
    "Australia/Sydney": { lat: -33.8688, lon: 151.2093 },
    "Pacific/Auckland": { lat: -36.8485, lon: 174.7633 }
};

/**
 * Returns estimated coordinates from the system timezone.
 * Falls back to dynamic longitude estimation based on UTC timezone offset if timezone is not hardcoded.
 * Detects Southern Hemisphere timezones to assign a realistic austral latitude (-33.8688) instead of boreal (+48.8566).
 *
 * @param {Date} [date] - Reference date for timezone offset calculation
 * @returns {{lat: number, lon: number}}
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
        // Fallback to offset calculation
    }

    // Dynamic longitude approximation: Earth rotates 360° in 1440 minutes (1° every 4 minutes)
    // Date.prototype.getTimezoneOffset() returns minutes behind UTC (e.g. UTC+2 is -120, UTC-5 is +300)
    // Therefore: offsetMinutesFromUtc = -d.getTimezoneOffset()
    // approxLon = offsetMinutesFromUtc / 4.0
    const tzOffsetMinutes = -d.getTimezoneOffset();
    const approxLon = tzOffsetMinutes / 4.0;

    // Detect Southern Hemisphere timezones to assign realistic austral latitude (-33.8688) instead of boreal (+48.8566)
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

    return { lat: approxLat, lon: approxLon };
}

/**
 * Calculates accurate astronomical solar cycle (Sunrise, Solar Noon, Sunset, Dusk/Night)
 * using standard NOAA solar ephemeris algorithms.
 *
 * Handles leap years, pure UTC day-of-year calculations (DST immune),
 * and polar extremes (Polar Night cosHA > 1, Midnight Sun cosHA < -1).
 *
 * @param {Date} [date] - Reference date
 * @param {number} [lat=48.8566] - Latitude in decimal degrees
 * @param {number} [lon=2.3522] - Longitude in decimal degrees
 * @returns {{morning: number, noon: number, evening: number, night: number}} minutes from midnight [0..1439]
 */
function calculateSolarSchedule(date, lat, lon) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const latitude = (typeof lat === "number" && !isNaN(lat)) ? lat : 48.8566;
    const longitude = (typeof lon === "number" && !isNaN(lon)) ? lon : 2.3522;

    const rad = Math.PI / 180.0;
    const deg = 180.0 / Math.PI;

    // 1. Day of the year calculated in pure UTC (avoids DST 1-hour shift artifacts)
    const year = d.getFullYear();
    const startOfYearUtc = Date.UTC(year, 0, 1);
    const dateUtc = Date.UTC(year, d.getMonth(), d.getDate());
    const dayOfYear = Math.floor((dateUtc - startOfYearUtc) / 86400000) + 1;

    // 2. Fractional year in radians taking leap years into account
    const isLeap = (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
    const daysInYear = isLeap ? 366.0 : 365.0;
    const gamma = (2.0 * Math.PI / daysInYear) * (dayOfYear - 1 + ((d.getHours() - 12) / 24.0));

    // 3. NOAA Equation of Time (in minutes)
    const eqTime = 229.18 * (0.000075 + 0.001868 * Math.cos(gamma) - 0.032077 * Math.sin(gamma)
                   - 0.014615 * Math.cos(2 * gamma) - 0.040849 * Math.sin(2 * gamma));

    // 4. Solar Declination (in radians)
    const decl = 0.006918 - 0.399912 * Math.cos(gamma) + 0.070257 * Math.sin(gamma)
                 - 0.006758 * Math.cos(2 * gamma) + 0.000907 * Math.sin(2 * gamma);

    // 5. Timezone offset in minutes (local time relative to UTC)
    const tzOffsetMinutes = -d.getTimezoneOffset();

    // 6. True Solar Noon in local minutes from midnight
    const solarNoonMinutes = 720.0 - 4.0 * longitude - eqTime + tzOffsetMinutes;

    /**
     * Calculates the Hour Angle for a given solar zenith angle.
     * Evaluates polar cases:
     * - cosHA > 1.0 : Polar Night (Sun never rises above zenith angle)
     * - cosHA < -1.0: Midnight Sun (Sun never drops below zenith angle)
     *
     * @param {number} zenithDeg
     * @returns {{ status: string, ha: number|null }} status: 'NORMAL' | 'POLAR_NIGHT' | 'MIDNIGHT_SUN'
     */
    function evaluateHourAngle(zenithDeg) {
        const cosHA = (Math.cos(zenithDeg * rad) - Math.sin(latitude * rad) * Math.sin(decl)) /
                      (Math.cos(latitude * rad) * Math.cos(decl));

        if (cosHA > 1.0) {
            // Sun remains below zenith all day -> Polar Night
            return { status: "POLAR_NIGHT", ha: null };
        }
        if (cosHA < -1.0) {
            // Sun remains above zenith all day -> Midnight Sun
            return { status: "MIDNIGHT_SUN", ha: null };
        }
        return { status: "NORMAL", ha: Math.acos(cosHA) * deg };
    }

    // 90.833° = standard sunrise/sunset zenith (including 34' refraction and 16' solar semi-diameter)
    const sunriseEval = evaluateHourAngle(90.833);
    // 96.0° = Civil dusk / twilight zenith
    const duskEval = evaluateHourAngle(96.0);

    let sunriseMin, sunsetMin, duskMin;

    if (sunriseEval.status === "POLAR_NIGHT") {
        // Polar Night: The sun does not rise above the horizon.
        if (duskEval.status === "NORMAL" && duskEval.ha !== null) {
            // Civil twilight glow occurs around solar noon
            const halfTwilight = duskEval.ha * 4.0;
            sunriseMin = solarNoonMinutes - halfTwilight;
            sunsetMin  = solarNoonMinutes + halfTwilight;
            duskMin    = sunsetMin + 30.0;
        } else {
            // Total polar night: 24 hours of darkness
            sunriseMin = solarNoonMinutes - 60.0;
            sunsetMin  = solarNoonMinutes + 60.0;
            duskMin    = solarNoonMinutes + 120.0;
        }
    } else if (sunriseEval.status === "MIDNIGHT_SUN") {
        // Midnight Sun: The sun does not set below the horizon (24 hours of sunlight).
        sunriseMin = solarNoonMinutes - 360.0; // ~6 hours before solar noon
        sunsetMin  = solarNoonMinutes + 360.0; // ~6 hours after solar noon
        duskMin    = solarNoonMinutes + 540.0; // ~9 hours after solar noon
    } else {
        // Standard sunrise, sunset, and twilight calculation
        const haSunrise = sunriseEval.ha;
        sunriseMin = solarNoonMinutes - haSunrise * 4.0;
        sunsetMin  = solarNoonMinutes + haSunrise * 4.0;

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
 * Returns effective schedule in minutes for the given configuration.
 *
 * @param {Date} [date]
 * @param {Object} [cfg]
 * @returns {{morning: number, noon: number, evening: number, night: number}}
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
        noon:    toMinutes(c.NoonHour !== undefined ? c.NoonHour : 12, c.NoonMinute !== undefined ? c.NoonMinute : 0),
        evening: toMinutes(c.EveningHour !== undefined ? c.EveningHour : 18, c.EveningMinute !== undefined ? c.EveningMinute : 0),
        night:   toMinutes(c.NightHour !== undefined ? c.NightHour : 22, c.NightMinute !== undefined ? c.NightMinute : 0)
    };
}

/**
 * Determines which time period is active based on current time and configured schedule.
 *
 * @param {Date} [date] - The date to check
 * @param {Object} [cfg] - The configuration object
 * @returns {string} One of: 'morning', 'noon', 'evening', 'night'
 */
function getCurrentPeriod(date, cfg) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const currentMinutes = toMinutes(d.getHours(), d.getMinutes());
    const schedule = getEffectiveSchedule(d, cfg);

    const morningMin = schedule.morning;
    const noonMin    = schedule.noon;
    const eveningMin = schedule.evening;
    const nightMin   = schedule.night;

    // Chronological slot check
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

    // Fallback for custom unordered periods
    const slots = [
        { name: "morning", start: morningMin },
        { name: "noon",    start: noonMin },
        { name: "evening", start: eveningMin },
        { name: "night",   start: nightMin }
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
 * Robustly converts a local filesystem path or URL into a safe QML/Qt file:// URL.
 * Handles spaces, '#' hash characters, '?' question marks, and special characters.
 *
 * @param {string} rawPath - Raw path or URL
 * @returns {string} Fully encoded, safe URL
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
            // keep as-is if decode fails
        }
    }

    const absPath = localPath.startsWith("/") ? localPath : "/" + localPath;
    try {
        return "file://" + encodeURI(absPath).replace(/#/g, "%23").replace(/\?/g, "%3F");
    } catch (e) {
        const safeSegments = absPath.split("/").map((seg) => encodeURIComponent(seg)).join("/");
        return "file://" + safeSegments;
    }
}



/**
 * Resolves the appropriate image URL for a given time period.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @param {Object} [cfg] - Configuration object
 * @param {function} [resolveLocalUrl] - Function to resolve package-relative URLs
 * @returns {string}
 */
function getImageForPeriod(period, cfg, resolveLocalUrl) {
    const c = cfg || {};
    const safeResolve = (typeof resolveLocalUrl === "function") ? resolveLocalUrl : ((p) => p);
    let customImage = "";
    let defaultFile = "";

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
 * Returns the start and end minutes for a given period in the schedule.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @param {Object} schedule - { morning: number, noon: number, evening: number, night: number }
 * @returns {{start: number, end: number}}
 */
function getPeriodRange(period, schedule) {
    if (!schedule || typeof schedule !== "object") {
        return { start: 0, end: 0 };
    }
    const morning = schedule.morning !== undefined ? schedule.morning : 360;
    const noon    = schedule.noon !== undefined ? schedule.noon : 720;
    const evening = schedule.evening !== undefined ? schedule.evening : 1080;
    const night   = schedule.night !== undefined ? schedule.night : 1320;

    switch (period) {
        case "morning":
            return { start: morning, end: noon };
        case "noon":
            return { start: noon, end: evening };
        case "evening":
            return { start: evening, end: night };
        case "night":
        default:
            return { start: night, end: morning };
    }
}

/**
 * Returns an appropriate icon name for a given period.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @returns {string}
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
 * Calculates the exact number of milliseconds remaining until the next period change.
 *
 * @param {Date} [date] - Reference date (defaults to current date if omitted)
 * @param {Object} [cfg] - Configuration object
 * @returns {number} Milliseconds remaining until the next transition
 */
function getMsUntilNextPeriod(date, cfg) {
    const d = (date instanceof Date && !isNaN(date.getTime())) ? date : new Date();
    const schedule = getEffectiveSchedule(d, cfg);

    const currentMs = ((d.getHours() * 60 + d.getMinutes()) * 60 + d.getSeconds()) * 1000 + d.getMilliseconds();

    // Distinct transition points in milliseconds from midnight
    const points = [
        schedule.morning * 60000,
        schedule.noon * 60000,
        schedule.evening * 60000,
        schedule.night * 60000
    ].sort((a, b) => a - b);

    // Find the next transition point strictly after currentMs
    for (let i = 0; i < points.length; ++i) {
        if (points[i] > currentMs) {
            return points[i] - currentMs;
        }
    }

    // If current time is past all transitions today, next transition is tomorrow's first point
    const msUntilMidnight = 86400000 - currentMs;
    return msUntilMidnight + points[0];
}


