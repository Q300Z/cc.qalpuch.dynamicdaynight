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
    return (Number(hour) || 0) * 60 + (Number(minute) || 0);
}

/**
 * Formats minutes from midnight into "HH:mm".
 * @param {number} minutes
 * @returns {string}
 */
function formatMinutes(minutes) {
    const normalized = (Math.round(minutes) % 1440 + 1440) % 1440;
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
 * @returns {{lat: number, lon: number}}
 */
function getSystemCoordinates() {
    try {
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        if (tz && TIMEZONE_COORDINATES[tz]) {
            return TIMEZONE_COORDINATES[tz];
        }
    } catch (e) {
        // Fallback default
    }
    return { lat: 48.8566, lon: 2.3522 }; // Default Paris
}

/**
 * Calculates accurate astronomical solar cycle (Sunrise, Solar Noon, Sunset, Dusk/Night)
 * using standard NOAA solar ephemeris algorithms.
 *
 * @param {Date} date
 * @param {number} lat - Latitude in decimal degrees
 * @param {number} lon - Longitude in decimal degrees
 * @returns {{morning: number, noon: number, evening: number, night: number}} minutes from midnight
 */
function calculateSolarSchedule(date, lat, lon) {
    const rad = Math.PI / 180.0;
    const deg = 180.0 / Math.PI;

    // Day of the year
    const startOfYear = new Date(date.getFullYear(), 0, 1);
    const dayOfYear = Math.floor((date - startOfYear) / 86400000) + 1;

    // Fractional year in radians
    const gamma = (2.0 * Math.PI / 365.0) * (dayOfYear - 1 + ((date.getHours() - 12) / 24.0));

    // Equation of Time (in minutes)
    const eqTime = 229.18 * (0.000075 + 0.001868 * Math.cos(gamma) - 0.032077 * Math.sin(gamma)
                   - 0.014615 * Math.cos(2 * gamma) - 0.040849 * Math.sin(2 * gamma));

    // Solar Declination (in radians)
    const decl = 0.006918 - 0.399912 * Math.cos(gamma) + 0.070257 * Math.sin(gamma)
                 - 0.006758 * Math.cos(2 * gamma) + 0.000907 * Math.sin(2 * gamma);

    // Timezone offset in minutes
    const tzOffsetMinutes = -date.getTimezoneOffset();

    // Solar noon in local minutes
    const solarNoonMinutes = 720.0 - 4.0 * lon - eqTime + tzOffsetMinutes;

    function getHourAngle(zenithDeg) {
        const cosHA = (Math.cos(zenithDeg * rad) - Math.sin(lat * rad) * Math.sin(decl)) /
                      (Math.cos(lat * rad) * Math.cos(decl));
        if (cosHA > 1.0) return null; // Polar night
        if (cosHA < -1.0) return null; // Midnight sun
        return Math.acos(cosHA) * deg;
    }

    // 90.833° = standard sunrise/sunset with atmospheric refraction
    const haSunrise = getHourAngle(90.833);
    // 96.0° = Civil dusk / twilight
    const haDusk = getHourAngle(96.0);

    const sunriseMin = (haSunrise !== null) ? solarNoonMinutes - haSunrise * 4.0 : 360;
    const sunsetMin  = (haSunrise !== null) ? solarNoonMinutes + haSunrise * 4.0 : 1080;
    const duskMin    = (haDusk !== null) ? solarNoonMinutes + haDusk * 4.0 : sunsetMin + 45;

    return {
        morning: Math.round(sunriseMin),
        noon: Math.round(solarNoonMinutes),
        evening: Math.round(sunsetMin),
        night: Math.round(duskMin)
    };
}

/**
 * Returns effective schedule in minutes for the given configuration.
 *
 * @param {Date} date
 * @param {Object} cfg
 * @returns {{morning: number, noon: number, evening: number, night: number}}
 */
function getEffectiveSchedule(date, cfg) {
    if (cfg && cfg.AutoSchedule) {
        const sysCoords = getSystemCoordinates();
        return calculateSolarSchedule(date, sysCoords.lat, sysCoords.lon);
    }

    return {
        morning: toMinutes(cfg.MorningHour !== undefined ? cfg.MorningHour : 6, cfg.MorningMinute !== undefined ? cfg.MorningMinute : 0),
        noon:    toMinutes(cfg.NoonHour !== undefined ? cfg.NoonHour : 12, cfg.NoonMinute !== undefined ? cfg.NoonMinute : 0),
        evening: toMinutes(cfg.EveningHour !== undefined ? cfg.EveningHour : 18, cfg.EveningMinute !== undefined ? cfg.EveningMinute : 0),
        night:   toMinutes(cfg.NightHour !== undefined ? cfg.NightHour : 22, cfg.NightMinute !== undefined ? cfg.NightMinute : 0)
    };
}

/**
 * Determines which time period is active based on current time and configured schedule.
 *
 * @param {Date} date - The date to check
 * @param {Object} cfg - The configuration object
 * @returns {string} One of: 'morning', 'noon', 'evening', 'night'
 */
function getCurrentPeriod(date, cfg) {
    const currentMinutes = toMinutes(date.getHours(), date.getMinutes());
    const schedule = getEffectiveSchedule(date, cfg);

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
 * Resolves the appropriate image URL for a given time period.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @param {Object} cfg - Configuration object
 * @param {function} resolveLocalUrl - Function to resolve package-relative URLs
 * @returns {string}
 */
function getImageForPeriod(period, cfg, resolveLocalUrl) {
    let customImage = "";
    let defaultFile = "";

    switch (period) {
        case "morning":
            customImage = cfg.MorningImage;
            defaultFile = "../images/matin.png";
            break;
        case "noon":
            customImage = cfg.NoonImage;
            defaultFile = "../images/midi.png";
            break;
        case "evening":
            customImage = cfg.EveningImage;
            defaultFile = "../images/soir.png";
            break;
        case "night":
        default:
            customImage = cfg.NightImage;
            defaultFile = "../images/nuit.png";
            break;
    }

    if (customImage && String(customImage).trim().length > 0) {
        const trimmed = String(customImage).trim();
        return trimmed.startsWith("file://") ? trimmed : "file://" + trimmed;
    }

    return resolveLocalUrl(defaultFile);
}

/**
 * Returns the start and end minutes for a given period in the schedule.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @param {Object} schedule - { morning: number, noon: number, evening: number, night: number }
 * @returns {{start: number, end: number}}
 */
function getPeriodRange(period, schedule) {
    if (!schedule) {
        return { start: 0, end: 0 };
    }
    switch (period) {
        case "morning":
            return { start: schedule.morning, end: schedule.noon };
        case "noon":
            return { start: schedule.noon, end: schedule.evening };
        case "evening":
            return { start: schedule.evening, end: schedule.night };
        case "night":
        default:
            return { start: schedule.night, end: schedule.morning };
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

/**
 * Returns the optimal accent color for a given daylight period.
 *
 * @param {string} period - 'morning', 'noon', 'evening', 'night'
 * @returns {string} Hex color code
 */
function getAccentColorForPeriod(period) {
    switch (period) {
        case "morning":
            return "#F39C12"; // Warm dawn / aurora amber
        case "noon":
            return "#1D99F3"; // Vibrant KDE Breeze sky blue
        case "evening":
            return "#E67E22"; // Golden sunset amber
        case "night":
            return "#6C5CE7"; // Deep twilight indigo
        default:
            return "#1D99F3";
    }
}

