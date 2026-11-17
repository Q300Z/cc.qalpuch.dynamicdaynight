// SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const timeUtilsPath = path.resolve(__dirname, "../contents/ui/TimeUtils.js");

function loadTimeUtils() {
    const code = fs.readFileSync(timeUtilsPath, "utf8");
    const context = vm.createContext({
        Date,
        Math,
        Number,
        String,
        Object,
        Intl,
        isNaN,
        encodeURI,
        encodeURIComponent,
        decodeURIComponent
    });
    vm.runInContext(code, context, {filename: timeUtilsPath});
    return context;
}

const TimeUtils = loadTimeUtils();

test("toMinutes et formatMinutes gèrent les bornes et entrées invalides", () => {
    assert.equal(TimeUtils.toMinutes(0, 0), 0);
    assert.equal(TimeUtils.toMinutes(6, 30), 390);
    assert.equal(TimeUtils.toMinutes(23, 59), 1439);
    assert.equal(TimeUtils.toMinutes("abc", undefined), 0);

    assert.equal(TimeUtils.formatMinutes(0), "00:00");
    assert.equal(TimeUtils.formatMinutes(390), "06:30");
    assert.equal(TimeUtils.formatMinutes(1440), "00:00");
    assert.equal(TimeUtils.formatMinutes(-60), "23:00");
    assert.equal(TimeUtils.formatMinutes(Number.NaN), "00:00");
});

test("calculateSolarSchedule retourne un cycle cohérent à Paris (été vs hiver) et gère les années bissextiles", () => {
    TimeUtils.clearSolarCache();

    const summer = new Date(2026, 5, 21, 10, 0, 0);
    const winter = new Date(2026, 11, 21, 10, 0, 0);
    const leapDay = new Date(2024, 1, 29, 12, 0, 0);

    const sSummer = TimeUtils.calculateSolarSchedule(summer, 48.8566, 2.3522);
    const sWinter = TimeUtils.calculateSolarSchedule(winter, 48.8566, 2.3522);
    const sLeap = TimeUtils.calculateSolarSchedule(leapDay, 48.8566, 2.3522);

    for (const sched of [sSummer, sWinter, sLeap]) {
        assert.ok(sched.morning < sched.noon, "morning < noon");
        assert.ok(sched.noon < sched.evening, "noon < evening");
        assert.ok(sched.evening < sched.night, "evening < night");
    }

    const summerDayLength = sSummer.evening - sSummer.morning;
    const winterDayLength = sWinter.evening - sWinter.morning;
    assert.ok(summerDayLength > winterDayLength + 240, "journée d'été nettement plus longue qu'en hiver");
});

test("calculateSolarSchedule gère la nuit polaire et le soleil de minuit", () => {
    TimeUtils.clearSolarCache();

    // Tromsø (69.65° N, 18.96° E)
    const polarNight = TimeUtils.calculateSolarSchedule(new Date(2026, 11, 21, 12, 0, 0), 69.65, 18.96);
    const midnightSun = TimeUtils.calculateSolarSchedule(new Date(2026, 5, 21, 12, 0, 0), 69.65, 18.96);

    for (const key of ["morning", "noon", "evening", "night"]) {
        assert.ok(Number.isInteger(polarNight[key]) && polarNight[key] >= 0 && polarNight[key] < 1440);
        assert.ok(Number.isInteger(midnightSun[key]) && midnightSun[key] >= 0 && midnightSun[key] < 1440);
    }
    assert.ok(polarNight.evening - polarNight.morning < midnightSun.evening - midnightSun.morning);
});

test("calculateSolarSchedule met en cache le résultat sur la journée", () => {
    TimeUtils.clearSolarCache();

    const morning = new Date(2026, 4, 10, 7, 15, 0);
    const afternoon = new Date(2026, 4, 10, 16, 45, 0);
    const nextDay = new Date(2026, 4, 11, 7, 15, 0);

    const first = TimeUtils.calculateSolarSchedule(morning, 48.8566, 2.3522);
    const second = TimeUtils.calculateSolarSchedule(afternoon, 48.8566, 2.3522);
    const third = TimeUtils.calculateSolarSchedule(nextDay, 48.8566, 2.3522);

    assert.strictEqual(first, second, "même référence en cache pour la même journée");
    assert.notStrictEqual(first, third, "nouveau calcul le lendemain");
});

test("getCurrentPeriod gère le cycle standard, le passage de minuit et les plages non triées", () => {
    const manualCfg = {
        AutoSchedule: false,
        MorningHour: 6, MorningMinute: 0,
        NoonHour: 12, NoonMinute: 0,
        EveningHour: 18, EveningMinute: 0,
        NightHour: 22, NightMinute: 0
    };

    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 2, 0), manualCfg), "night");
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 6, 0), manualCfg), "morning");
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 13, 30), manualCfg), "noon");
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 19, 0), manualCfg), "evening");
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 23, 30), manualCfg), "night");

    // Plages manuelles non ordonnées chronologiquement (repli trié)
    const unsortedCfg = {
        AutoSchedule: false,
        MorningHour: 10, MorningMinute: 0,
        NoonHour: 14, NoonMinute: 0,
        EveningHour: 19, EveningMinute: 0,
        NightHour: 2, NightMinute: 0
    };
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 3, 0), unsortedCfg), "night");
    assert.equal(TimeUtils.getCurrentPeriod(new Date(2026, 0, 1, 11, 0), unsortedCfg), "morning");
});

test("getMsUntilNextPeriod calcule le délai exact jusqu'au prochain changement", () => {
    const cfg = {
        AutoSchedule: false,
        MorningHour: 6, MorningMinute: 0,
        NoonHour: 12, NoonMinute: 0,
        EveningHour: 18, EveningMinute: 0,
        NightHour: 22, NightMinute: 0
    };

    // 11:59:30.000 -> 30s avant 12:00
    assert.equal(TimeUtils.getMsUntilNextPeriod(new Date(2026, 0, 1, 11, 59, 30, 0), cfg), 30000);

    // 23:00:00.000 -> 1h + 6h = 7h avant 06:00 le lendemain
    assert.equal(TimeUtils.getMsUntilNextPeriod(new Date(2026, 0, 1, 23, 0, 0, 0), cfg), 7 * 3600 * 1000);
});

test("toSafeFileUrl encode les caractères spéciaux et préserve les URL spéciales", () => {
    assert.equal(TimeUtils.toSafeFileUrl(""), "");
    assert.equal(TimeUtils.toSafeFileUrl(null), "");
    assert.equal(TimeUtils.toSafeFileUrl("qrc:/images/test.png"), "qrc:/images/test.png");
    assert.equal(TimeUtils.toSafeFileUrl("https://example.com/a.png"), "https://example.com/a.png");

    assert.equal(
        TimeUtils.toSafeFileUrl("/home/user/Mes Images/photo #1 [test]?.png"),
        "file:///home/user/Mes%20Images/photo%20%231%20%5Btest%5D%3F.png"
    );
    assert.equal(
        TimeUtils.toSafeFileUrl("file:///home/user/Mon%20Fond.png"),
        "file:///home/user/Mon%20Fond.png"
    );
});

test("getDefaultImageForPeriod, getImageForPeriod et getPeriodDisplayName résolvent correctement", () => {
    const resolver = (p) => "resolved:" + p;
    assert.equal(TimeUtils.getDefaultImageForPeriod("morning", resolver), "resolved:../images/matin.png");
    assert.equal(TimeUtils.getDefaultImageForPeriod("unknown", resolver), "resolved:../images/nuit.png");

    assert.equal(
        TimeUtils.getImageForPeriod("noon", {NoonImage: "/tmp/midi #custom.png"}, resolver),
        "file:///tmp/midi%20%23custom.png"
    );
    assert.equal(
        TimeUtils.getImageForPeriod("evening", {}, resolver),
        "resolved:../images/soir.png"
    );

    assert.equal(TimeUtils.getPeriodDisplayName("morning"), "Morning");
    assert.equal(
        TimeUtils.getPeriodDisplayName("night", (_domain, s) => "FR:" + s),
        "FR:Night"
    );
});
