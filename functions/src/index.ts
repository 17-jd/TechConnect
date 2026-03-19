import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { CloudTasksClient } from "@google-cloud/tasks";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const PROJECT_ID = process.env.GCLOUD_PROJECT || "";
const LOCATION = "us-central1";
const QUEUE_NAME = "wave-notifications";
const FUNCTIONS_URL = `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net`;

// ---------- Haversine distance in km ----------
function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ---------- Schedule a Cloud Task ----------
async function scheduleWaveTask(requestId: string, wave: number, delaySeconds: number) {
  const client = new CloudTasksClient();
  const parent = client.queuePath(PROJECT_ID, LOCATION, QUEUE_NAME);

  const payload = JSON.stringify({ requestId, wave });
  const task = {
    httpRequest: {
      httpMethod: "POST" as const,
      url: `${FUNCTIONS_URL}/processWave`,
      headers: { "Content-Type": "application/json" },
      body: Buffer.from(payload).toString("base64"),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });
}

// ---------- Send FCM push to a batch of tokens ----------
async function sendPushBatch(tokens: string[], requestId: string, category: string, price: number) {
  if (tokens.length === 0) return;
  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title: "New Job Request!",
      body: `${category} • $${price} — tap to view details`,
    },
    data: {
      requestId,
      type: "new_request",
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };
  await messaging.sendEachForMulticast(message);
}

// ============================================================
// TRIGGER 1: New service request created → start wave 0
// ============================================================
export const onRequestCreated = onDocumentCreated(
  "serviceRequests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== "open") return;

    const requestId = event.params.requestId;
    const { latitude, longitude, category, price } = data;

    // Fetch all online engineers with FCM tokens
    const engineersSnap = await db
      .collection("users")
      .where("role", "==", "engineer")
      .where("isOnline", "==", true)
      .get();

    const engineers = engineersSnap.docs
      .map((doc) => ({ id: doc.id, ...doc.data() } as any))
      .filter((e) => e.fcmToken && e.latitude != null && e.longitude != null);

    if (engineers.length === 0) return;

    // Sort by distance from customer
    engineers.sort((a: any, b: any) =>
      haversineKm(latitude, longitude, a.latitude, a.longitude) -
      haversineKm(latitude, longitude, b.latitude, b.longitude)
    );

    // Wave 0: just the closest engineer
    const wave0 = engineers.slice(0, 1);
    const tokens0 = wave0.map((e: any) => e.fcmToken as string);
    const notifiedIds = wave0.map((e: any) => e.id as string);

    await sendPushBatch(tokens0, requestId, category, price);
    await db.collection("serviceRequests").doc(requestId).update({
      notificationWave: 0,
      notifiedEngineerIds: admin.firestore.FieldValue.arrayUnion(...notifiedIds),
    });

    // Schedule wave 1 if there are more engineers
    if (engineers.length > 1) {
      await scheduleWaveTask(requestId, 1, 30);
    }
  }
);

// ============================================================
// TRIGGER 2: Request accepted → cancel future waves (by marking)
// ============================================================
export const onRequestAccepted = onDocumentUpdated(
  "serviceRequests/{requestId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only act when status changes away from "open"
    if (before.status === "open" && after.status !== "open") {
      // Mark as accepted so processWave bails out early
      // (Cloud Tasks doesn't support cancellation by task name without storing task IDs,
      //  so we rely on the status check inside processWave)
      console.log(`Request ${event.params.requestId} accepted — future waves will self-cancel`);
    }
  }
);

// ============================================================
// HTTP FUNCTION: processWave — called by Cloud Tasks
// ============================================================
export const processWave = onRequest(async (req, res) => {
  const { requestId, wave } = req.body as { requestId: string; wave: number };
  if (!requestId || wave == null) {
    res.status(400).send("Missing requestId or wave");
    return;
  }

  const requestRef = db.collection("serviceRequests").doc(requestId);
  const requestDoc = await requestRef.get();
  const data = requestDoc.data();

  // Bail if no longer open
  if (!data || data.status !== "open") {
    res.status(200).send("Request no longer open — wave cancelled");
    return;
  }

  const { latitude, longitude, category, price, notifiedEngineerIds = [] } = data;

  // Fetch all online engineers not yet notified
  const engineersSnap = await db
    .collection("users")
    .where("role", "==", "engineer")
    .where("isOnline", "==", true)
    .get();

  const candidates = engineersSnap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() } as any))
    .filter(
      (e) =>
        e.fcmToken &&
        e.latitude != null &&
        e.longitude != null &&
        !notifiedEngineerIds.includes(e.id)
    );

  if (candidates.length === 0) {
    res.status(200).send("No more engineers to notify");
    return;
  }

  // Sort by distance
  candidates.sort((a: any, b: any) =>
    haversineKm(latitude, longitude, a.latitude, a.longitude) -
    haversineKm(latitude, longitude, b.latitude, b.longitude)
  );

  const batch = candidates.slice(0, 10);
  const tokens = batch.map((e: any) => e.fcmToken as string);
  const ids = batch.map((e: any) => e.id as string);

  await sendPushBatch(tokens, requestId, category, price);
  await requestRef.update({
    notificationWave: wave,
    notifiedEngineerIds: admin.firestore.FieldValue.arrayUnion(...ids),
  });

  // Schedule next wave if more engineers remain
  const remaining = candidates.length - 10;
  if (remaining > 0) {
    await scheduleWaveTask(requestId, wave + 1, 30);
  }

  res.status(200).send(`Wave ${wave} sent to ${batch.length} engineers`);
});
