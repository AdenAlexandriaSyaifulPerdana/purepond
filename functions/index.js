const { onValueWritten } = require("firebase-functions/database");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// =====================================================
// ================= KONFIGURASI =======================
// =====================================================

const AMMONIA_LIMIT = 0.50;
const TURBIDITY_LIMIT = 120.0;

const AMMONIA_150 = AMMONIA_LIMIT * 1.5; // 0.75 ppm
const TURBIDITY_150 = TURBIDITY_LIMIT * 1.5; // 180 NTU

const RTDB_INSTANCE = "purepond-67695-default-rtdb";
const REGION = "asia-southeast1";

// =====================================================
// ================= HELPER ============================
// =====================================================

function getNumber(value, fallback = 0) {
  if (value === null || value === undefined) return fallback;
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function getBool(value, fallback = false) {
  if (value === null || value === undefined) return fallback;
  return value === true;
}

function getString(value, fallback = "") {
  if (value === null || value === undefined) return fallback;
  return String(value);
}

function readSensor(data) {
  const ammonia = data.ammonia || {};
  const turbidity = data.turbidity || {};
  const lower = data.waterLevelLower || {};
  const upper = data.waterLevelUpper || {};
  const system = data.system || {};

  return {
    ammonia: {
      value: getNumber(ammonia.value),
      raw: getNumber(ammonia.raw),
      voltage: getNumber(ammonia.voltage),
      unit: getString(ammonia.unit, "ppm"),
    },
    turbidity: {
      value: getNumber(turbidity.value),
      raw: getNumber(turbidity.raw),
      voltage: getNumber(turbidity.voltage),
      unit: getString(turbidity.unit, "NTU"),
    },
    waterLevelLower: {
      raw: getNumber(lower.raw),
      voltage: getNumber(lower.voltage),
      percent: getNumber(lower.percent),
      detected: getBool(lower.detected),
      empty: getBool(lower.empty),
    },
    waterLevelUpper: {
      distanceCm: getNumber(upper.distanceCm, 999),
      full: getBool(upper.full),
      status: getString(upper.status, "not_detected"),
    },
    autoMode: getBool(data.autoMode, true),
    isDraining: getBool(data.isDraining),
    isFilling: getBool(data.isFilling),
    state: getString(data.state, "UNKNOWN"),
    drainCycleLocked: getBool(data.drainCycleLocked),
    drainTriggerReason: getString(data.drainTriggerReason),
    systemMillis: getNumber(system.millis),
  };
}

function analyzeQuality(sensor) {
  const ammoniaOver100 = sensor.ammonia.value >= AMMONIA_LIMIT;
  const turbidityOver100 = sensor.turbidity.value > TURBIDITY_LIMIT;

  const ammoniaOver150 = sensor.ammonia.value >= AMMONIA_150;
  const turbidityOver150 = sensor.turbidity.value > TURBIDITY_150;

  const over100Count =
    (ammoniaOver100 ? 1 : 0) + (turbidityOver100 ? 1 : 0);

  const drainCondition =
    ammoniaOver150 || turbidityOver150 || over100Count >= 2;

  const warningCondition = over100Count === 1 && !drainCondition;

  let parameter = "";
  let value = 0;
  let threshold = 0;

  if (ammoniaOver100 && turbidityOver100) {
    parameter = "both";
    value = Math.max(sensor.ammonia.value, sensor.turbidity.value);
    threshold = 0;
  } else if (ammoniaOver100) {
    parameter = "ammonia";
    value = sensor.ammonia.value;
    threshold = AMMONIA_LIMIT;
  } else if (turbidityOver100) {
    parameter = "turbidity";
    value = sensor.turbidity.value;
    threshold = TURBIDITY_LIMIT;
  }

  if (ammoniaOver150 && !turbidityOver150) {
    parameter = "ammonia";
    value = sensor.ammonia.value;
    threshold = AMMONIA_150;
  }

  if (turbidityOver150 && !ammoniaOver150) {
    parameter = "turbidity";
    value = sensor.turbidity.value;
    threshold = TURBIDITY_150;
  }

  if (ammoniaOver150 && turbidityOver150) {
    parameter = "both";
    value = Math.max(sensor.ammonia.value, sensor.turbidity.value);
    threshold = 0;
  }

  return {
    ammoniaOver100,
    turbidityOver100,
    ammoniaOver150,
    turbidityOver150,
    over100Count,
    warningCondition,
    drainCondition,
    parameter,
    value,
    threshold,
  };
}

function parameterLabel(parameter) {
  if (parameter === "ammonia") return "Amonia";
  if (parameter === "turbidity") return "Kekeruhan";
  if (parameter === "both") return "Amonia dan kekeruhan";
  return "Kualitas air";
}

function parameterUnit(parameter) {
  if (parameter === "ammonia") return "ppm";
  if (parameter === "turbidity") return "NTU";
  return "";
}

function buildHistorySnapshot(sensor) {
  return {
    ammonia: sensor.ammonia,
    turbidity: sensor.turbidity,
    waterLevelLower: sensor.waterLevelLower,
    waterLevelUpper: sensor.waterLevelUpper,
    autoMode: sensor.autoMode,
    isDraining: sensor.isDraining,
    isFilling: sensor.isFilling,
    state: sensor.state,
    drainCycleLocked: sensor.drainCycleLocked,
    drainTriggerReason: sensor.drainTriggerReason,
    systemMillis: sensor.systemMillis,
  };
}

// =====================================================
// ================= FIRESTORE NOTIFICATION ============
// =====================================================

async function saveNotification({
  title,
  body,
  type,
  parameter,
  value,
  threshold,
}) {
  await db.collection("notifications").add({
    title,
    judul: title,
    body,
    isi: body,
    type,
    parameter,
    value,
    nilai: value,
    threshold,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// =====================================================
// ================= FCM ===============================
// =====================================================

async function getFcmTokenDocs() {
  const snapshot = await db
    .collection("fcmTokens")
    .where("enabled", "==", true)
    .get();

  return snapshot.docs;
}

async function sendPushNotification({ title, body, type, parameter }) {
  const tokenDocs = await getFcmTokenDocs();

  if (tokenDocs.length === 0) {
    console.log("Tidak ada FCM token aktif.");
    return;
  }

  const tokens = tokenDocs
    .map((doc) => doc.data().token)
    .filter((token) => typeof token === "string" && token.length > 0);

  if (tokens.length === 0) {
    console.log("Token kosong.");
    return;
  }

  const chunkSize = 500;

  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);

    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: {
        title,
        body,
      },
      data: {
        title,
        body,
        type,
        parameter,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "purepond_alert_channel",
          sound: "default",
        },
      },
    });

    const batch = db.batch();

    response.responses.forEach((result, index) => {
      if (!result.success) {
        const errorCode = result.error && result.error.code;

        if (
          errorCode === "messaging/registration-token-not-registered" ||
          errorCode === "messaging/invalid-registration-token"
        ) {
          const token = chunk[index];
          const tokenDoc = tokenDocs.find((doc) => doc.data().token === token);

          if (tokenDoc) {
            batch.update(tokenDoc.ref, {
              enabled: false,
              disabledAt: admin.firestore.FieldValue.serverTimestamp(),
              disabledReason: errorCode,
            });
          }
        }
      }
    });

    await batch.commit();

    console.log(
      `FCM terkirim. Success: ${response.successCount}, Failed: ${response.failureCount}`
    );
  }
}

// =====================================================
// ================= WARNING / DRAIN ALERT =============
// =====================================================

async function handleQualityAlert(sensor, analysis) {
  const runtimeRef = db.collection("runtime").doc("waterQualityAlert");
  const runtimeSnap = await runtimeRef.get();
  const runtime = runtimeSnap.exists ? runtimeSnap.data() : {};

  const currentWarningKey = runtime.currentWarningKey || "";
  const currentDrainKey = runtime.currentDrainKey || "";

  const warningKey = analysis.warningCondition
    ? `warning-${analysis.parameter}`
    : "";

  const drainKey = analysis.drainCondition
    ? `drain-${analysis.parameter}`
    : "";

  const updates = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // ================= WARNING =================
  if (analysis.warningCondition && warningKey !== currentWarningKey) {
    const parameter = analysis.parameter;
    const label = parameterLabel(parameter);
    const unit = parameterUnit(parameter);

    const title = "Peringatan Kualitas Air";
    const body =
      `${label} melebihi batas normal. ` +
      `Nilai saat ini ${analysis.value.toFixed(2)} ${unit}.`;

    await saveNotification({
      title,
      body,
      type: "warning",
      parameter,
      value: analysis.value,
      threshold: analysis.threshold,
    });

    await sendPushNotification({
      title,
      body,
      type: "warning",
      parameter,
    });

    updates.currentWarningKey = warningKey;
  }

  if (!analysis.warningCondition) {
    updates.currentWarningKey = "";
  }

  // ================= DRAIN =================
  if (analysis.drainCondition && drainKey !== currentDrainKey) {
    const parameter = analysis.parameter;
    const label = parameterLabel(parameter);

    const title = sensor.autoMode
      ? "Pengurasan Otomatis Diperlukan"
      : "Kualitas Air Buruk";

    const body = sensor.autoMode
      ? `${label} melewati batas pengurasan. Sistem akan melakukan pengurasan otomatis.`
      : `${label} melewati batas pengurasan, tetapi otomatisasi sedang mati.`;

    await saveNotification({
      title,
      body,
      type: "drain",
      parameter,
      value: analysis.value,
      threshold: analysis.threshold,
    });

    await sendPushNotification({
      title,
      body,
      type: "drain",
      parameter,
    });

    updates.currentDrainKey = drainKey;
  }

  if (!analysis.drainCondition) {
    updates.currentDrainKey = "";
  }

  await runtimeRef.set(updates, { merge: true });
}

// =====================================================
// ================= HISTORY PENGURASAN ================
// =====================================================

async function handleDrainSession(beforeSensor, afterSensor) {
  const sessionRef = db.collection("runtime").doc("currentDrainSession");

  const beforeLocked = beforeSensor.drainCycleLocked;
  const afterLocked = afterSensor.drainCycleLocked;

  // Siklus pengurasan baru mulai
  if (!beforeLocked && afterLocked) {
    const startData = buildHistorySnapshot(afterSensor);

    await sessionRef.set({
      trigger: afterSensor.drainTriggerReason || "unknown",
      startData,
      startMillis: afterSensor.systemMillis,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Drain session started.");
    return;
  }

  // Siklus pengurasan selesai
  if (beforeLocked && !afterLocked) {
    const sessionSnap = await sessionRef.get();

    const finishData = buildHistorySnapshot(afterSensor);

    let startData = buildHistorySnapshot(beforeSensor);
    let trigger = beforeSensor.drainTriggerReason || "unknown";
    let startMillis = beforeSensor.systemMillis;

    if (sessionSnap.exists) {
      const session = sessionSnap.data();
      startData = session.startData || startData;
      trigger = session.trigger || trigger;
      startMillis = session.startMillis || startMillis;
    }

    const finishMillis = afterSensor.systemMillis;
    const duration =
      finishMillis > startMillis
        ? Math.round((finishMillis - startMillis) / 1000)
        : 0;

    await db.collection("history").add({
      type: "Otomatis",
      tipe: "Otomatis",
      trigger,
      pemicu: trigger,

      ammonia: getNumber(startData.ammonia && startData.ammonia.value),
      ammoniaRaw: getNumber(startData.ammonia && startData.ammonia.raw),
      ammoniaVoltage: getNumber(
        startData.ammonia && startData.ammonia.voltage
      ),

      turbidity: getNumber(startData.turbidity && startData.turbidity.value),
      turbidityRaw: getNumber(startData.turbidity && startData.turbidity.raw),
      turbidityVoltage: getNumber(
        startData.turbidity && startData.turbidity.voltage
      ),

      waterLevelLower:
        startData.waterLevelLower || finishData.waterLevelLower || {},
      waterLevelUpper:
        finishData.waterLevelUpper || startData.waterLevelUpper || {},

      startData,
      finishData,

      isDraining: afterSensor.isDraining,
      isFilling: afterSensor.isFilling,
      autoMode: afterSensor.autoMode,
      state: afterSensor.state,

      duration,
      durasi: duration,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await sessionRef.delete();

    console.log("Drain session finished. History saved.");
  }
}

// =====================================================
// ================= MAIN FUNCTION =====================
// =====================================================

exports.onRealtimeCurrentChanged = onValueWritten(
  {
    ref: "/realtime/current",
    instance: RTDB_INSTANCE,
    region: REGION,
  },
  async (event) => {
    if (!event.data.after.exists()) {
      return null;
    }

    const beforeData = event.data.before.exists()
      ? event.data.before.val()
      : {};

    const afterData = event.data.after.val() || {};

    const beforeSensor = readSensor(beforeData);
    const afterSensor = readSensor(afterData);

    const analysis = analyzeQuality(afterSensor);

    await handleQualityAlert(afterSensor, analysis);
    await handleDrainSession(beforeSensor, afterSensor);

    return null;
  }
);