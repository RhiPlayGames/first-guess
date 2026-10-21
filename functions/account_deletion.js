"use strict";
// Account deletion handlers. Deploy individual functions only after integration verification.
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {getApps, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldPath, FieldValue} = require("firebase-admin/firestore");
const {validateRequest, chooseSuccessor} = require("./deletion_policy");
const crypto = require("node:crypto");
if (getApps().length === 0) initializeApp();
const db = getFirestore();
const jobs = db.collection("account_deletion_jobs");
const STEPS = ["leagues", "globalLeaderboards", "names", "playerData", "auth"];
const LEASE_MS = 120000;
const HEARTBEAT_MS = 30000;
function receiptHash(receipt) {
  if (typeof receipt !== "string" || !/^[A-Za-z0-9_-]{43}$/.test(receipt)) {
    throw new HttpsError("invalid-argument", "Invalid deletion receipt");
  }
  return crypto.createHash("sha256").update(receipt, "utf8").digest("hex");
}


async function cleanSnapshots(ref, uid) {
  const refs = await ref.listDocuments();
  for (const doc of refs) {
    const snap = await doc.get();
    if (!snap.exists) continue;
    const movements = snap.get("movements");
    if (movements && Object.prototype.hasOwnProperty.call(movements, uid)) {
      await doc.update(new FieldPath("movements", uid), FieldValue.delete());
    }
  }
}
async function cleanLeague(ref, uid) {
  const snap = await ref.get();
  if (!snap.exists) return;
  const data = snap.data();
  if (!((data.memberIds || []).includes(uid) || data.ownerId === uid)) return;
  const inviteQuery = () => db.collection("league_invites").where("leagueId", "==", ref.id).get();
  // Clear private rank movement entries BEFORE dropping membership, so retries
  // do not lose the ability to discover this league.
  await cleanSnapshots(ref.collection("rank_snapshots"), uid);
  if (!chooseSuccessor(data.memberIds, uid, data.ownerId).remaining.length) {
    // Recheck via transaction: an additional member may have joined meanwhile.
    const empty = await db.runTransaction(async (tx) => {
      const current = await tx.get(ref);
      if (!current.exists) return false;
      const f = current.data();
      if (chooseSuccessor(f.memberIds, uid, f.ownerId).remaining.length) return false;
      tx.delete(ref);
      return true;
    });
    if (empty) {
      for (const invite of (await inviteQuery()).docs) await invite.ref.delete();
      // Delete subcollections even when the league parent was already deleted.
      await db.recursiveDelete(ref);
      return;
    }
  }
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    if (!fresh.exists) return;
    const f = fresh.data();
    const {remaining, nextOwner} = chooseSuccessor(f.memberIds, uid, f.ownerId);
    if (!remaining.length) throw new Error("league membership changed; retry");
    tx.update(ref, {memberIds: remaining, memberCount: remaining.length, ownerId: nextOwner});
    tx.delete(ref.collection("members").doc(uid));
    if (f.ownerId === uid) tx.set(ref.collection("members").doc(nextOwner), {role: "owner"}, {merge: true});
  });
  const latest = await ref.get();
  if (!latest.exists) return;
  for (const invite of (await inviteQuery()).docs) {
    const changes = {memberCount: latest.get("memberCount")};
    if (invite.get("ownerId") === uid) changes.ownerId = latest.get("ownerId");
    if (invite.get("createdBy") === uid) changes.createdBy = latest.get("ownerId");
    await invite.ref.update(changes);
  }
  await cleanSnapshots(ref.collection("rank_snapshots"), uid);
}
async function runStep(step, uid) {
  if (step === "leagues") {
    const refs = new Map();
    for (const snap of (await db.collection("leagues").where("memberIds", "array-contains", uid).get()).docs) refs.set(snap.id, snap.ref);
    for (const snap of (await db.collection("leagues").where("ownerId", "==", uid).get()).docs) refs.set(snap.id, snap.ref);
    for (const ref of refs.values()) await cleanLeague(ref, uid);
  } else if (step === "globalLeaderboards") {
    for (const period of await db.collection("global_leaderboards").listDocuments()) {
      await period.collection("players").doc(uid).delete();
      await cleanSnapshots(period.collection("rank_snapshots"), uid);
    }
  } else if (step === "names") {
    for (const name of (await db.collection("player_names").where("userId", "==", uid).get()).docs) await name.ref.delete();
  } else if (step === "playerData") {
    await db.recursiveDelete(db.collection("players").doc(uid));
  } else if (step === "auth") {
    try { await getAuth().deleteUser(uid); }
    catch (e) { if (e.code !== "auth/user-not-found") throw e; }
  }
}
async function claim(ref) {
  const token = crypto.randomUUID();
  const now = Date.now();
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const job = snap.data();
    if (job.status === "completed" || (job.leaseUntilMs || 0) > now) return false;
    if ((job.nextAttemptMs || 0) > now) return false;
    tx.update(ref, {status: "running", leaseOwner: token, leaseUntilMs: now + LEASE_MS, updatedAt: FieldValue.serverTimestamp()});
    return true;
  });
  return claimed ? token : null;
}
async function processJob(ref) {
  const token = await claim(ref);
  if (!token) return false;
  let leaseLost = false;
  let renewalBusy = false;
  const renew = async () => {
    if (renewalBusy || leaseLost) return;
    renewalBusy = true;
    try {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists || snap.get("leaseOwner") !== token ||
            (snap.get("leaseUntilMs") || 0) < Date.now()) {
          throw new Error("Lease no longer held");
        }
        tx.update(ref, {leaseUntilMs: Date.now() + LEASE_MS});
      });
    } catch (error) {
      leaseLost = true;
      console.error("Account deletion worker lost lease", ref.id, error.code || "unknown");
    } finally { renewalBusy = false; }
  };
  const heartbeat = setInterval(() => { void renew(); }, HEARTBEAT_MS);
  try {
    for (let index = 0; index < STEPS.length; index++) {
      if (leaseLost) throw new Error("Lease lost");
      const snap = await ref.get();
      if (!snap.exists) throw new Error("Job disappeared");
      const job = snap.data();
      if (job.leaseOwner !== token) return false;
      if ((job.step || 0) > index) continue;
      // The lease must be renewed before every step. Jobs taking longer than the
      // lease must be split into smaller units prior to production deployment.
      await db.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        if (!current.exists || current.get("leaseOwner") !== token || (current.get("leaseUntilMs") || 0) < Date.now()) {
          throw new Error("Lease expired");
        }
        tx.update(ref, {leaseUntilMs: Date.now() + LEASE_MS});
      });
      await runStep(STEPS[index], ref.id);
      if (leaseLost) throw new Error("Lease lost during step");
      await db.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        if (!current.exists || current.get("leaseOwner") !== token || (current.get("leaseUntilMs") || 0) < Date.now()) {
          throw new Error("Lease expired after stage");
        }
        tx.update(ref, {step: index + 1, leaseUntilMs: Date.now() + LEASE_MS, updatedAt: FieldValue.serverTimestamp()});
      });
    }
    await ref.update({status: "completed", leaseOwner: FieldValue.delete(), leaseUntilMs: 0, completedAt: FieldValue.serverTimestamp()});
    return true;
  } catch (e) {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists || snap.get("leaseOwner") !== token) return;
      const attempts = (snap.get("attempts") || 0) + 1;
      tx.update(ref, {status: "retry", attempts, nextAttemptMs: Date.now() + Math.min(3600000, 60000 * Math.pow(2, Math.min(attempts, 5))), leaseOwner: FieldValue.delete(), leaseUntilMs: 0, lastErrorCode: String(e.code || "unknown").slice(0, 80)});
    });
    throw e;
  } finally { clearInterval(heartbeat); }
}
const requestAccountDeletion = onCall({region: "us-central1", enforceAppCheck: true}, async (request) => {
  // Firebase Functions already verifies the Authentication ID token, and
  // enforceAppCheck above verifies the app origin. Explicit typed confirmation
  // is still required by validateRequest for every account type.
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Sign-in required");
  }
  const uid = request.auth.uid;
  let userRecord;
  try { userRecord = await getAuth().getUser(uid); }
  catch (e) {
    if (e.code === "auth/user-not-found") throw new HttpsError("unauthenticated", "Account no longer exists");
    throw e;
  }
  // Older anonymous accounts have no external credential to reauthenticate.
  // Never apply this exemption to linked, email, phone, Google or Apple users.
  const verifiedAnonymousGuest =
      request.auth.token?.firebase?.sign_in_provider === "anonymous" &&
      Array.isArray(userRecord.providerData) && userRecord.providerData.length === 0 &&
      !userRecord.email && !userRecord.phoneNumber;
  const result = validateRequest(request, undefined, {verifiedAnonymousGuest});
  if (!result.ok) throw new HttpsError(result.code, result.message);
  // Older released clients submit confirmation but do not send a receipt.
  // Keep supporting these authenticated requests; only receipt-aware clients
  // can use the post-deletion status verification endpoint.
  const suppliedReceipt = request.data?.receipt;
  const hash = suppliedReceipt == null ? null : receiptHash(suppliedReceipt);
  const ref = jobs.doc(uid);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (!existing.exists) {
      const job = {status: "pending", step: 0, attempts: 0,
        nextAttemptMs: Date.now(), leaseUntilMs: 0,
        requestedAt: FieldValue.serverTimestamp()};
      if (hash !== null) job.receiptHash = hash;
      tx.create(ref, job);
    } else {
      const previousHash = existing.get("receiptHash") ?? null;
      if (previousHash !== hash) {
        throw new HttpsError("failed-precondition", "A deletion request already exists");
      }
    }
  });
  // The updated website requires this acknowledgement. Legacy app versions
  // can still submit requests without receipts, but cannot verify completion.
  return {accepted: true, receiptBound: hash !== null};
});
// Status checking does not need Firebase Auth after user removal. The 256-bit
// local receipt authorises access to this job's *status only*. Never return PII.
const getAccountDeletionStatus = onCall({region: "us-central1", enforceAppCheck: true}, async (request) => {
  const uid = request.data?.uid;
  const receipt = request.data?.receipt;
  if (typeof uid !== "string" || uid.length < 15 || uid.length > 128 || !/^[A-Za-z0-9_-]+$/.test(uid)) {
    throw new HttpsError("invalid-argument", "Invalid request");
  }
  const hash = receiptHash(receipt);
  const snap = await jobs.doc(uid).get();
  const known = snap.exists && typeof snap.get("receiptHash") === "string"
      ? snap.get("receiptHash") : "";
  const expected = Buffer.from(hash, "hex");
  const actual = /^[0-9a-f]{64}$/.test(known) ? Buffer.from(known, "hex") : Buffer.alloc(32);
  if (!crypto.timingSafeEqual(expected, actual)) {
    throw new HttpsError("permission-denied", "Cannot verify this deletion request");
  }
  return {status: snap.get("status") === "completed" ? "completed" : "pending"};
});
// Deployment of the scheduler is NOT authorised by this review package.
const resumeAccountDeletions = onSchedule({schedule: "every 5 minutes", region: "us-central1", maxInstances: 1, timeoutSeconds: 540}, async () => {
  let cursor = null;
  const startedAt = Date.now();
  while (Date.now() - startedAt < 7 * 60 * 1000) {
    let query = jobs.where("status", "in", ["pending", "retry", "running"])
        .orderBy(FieldPath.documentId()).limit(40);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    for (const job of page.docs) {
      if (Date.now() - startedAt >= 7 * 60 * 1000) break;
      try { await processJob(job.ref); }
      catch (e) { console.error("Account deletion job needs retry", job.id, e.code || "unknown"); }
    }
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 40) break;
  }
});
module.exports = {requestAccountDeletion, getAccountDeletionStatus, resumeAccountDeletions, processJob, runStep};
