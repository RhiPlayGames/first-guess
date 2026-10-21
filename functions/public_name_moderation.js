"use strict";
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getApps, initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
if (!getApps().length) initializeApp();
const db = getFirestore();

// Use word boundaries for common terms to avoid innocent embedded matches.
// Review and extend this UK-English starter list as reports arrive.
const words = new Set([
  "fuck", "fucker", "fucking", "fuk", "shit", "shite", "bitch", "cunt",
  "cock", "pussy", "arsehole", "asshole", "wanker", "twat", "bastard",
  "slut", "whore", "nigger", "nigga", "faggot", "nonce", "paedo", "pedo",
  "motherfucker", "dickhead", "bullshit", "bollocks"
]);
const strongWords = ["fuck", "cunt", "nigger", "nigga", "faggot", "motherfucker"];
const impersonation = /^(rhi\s*play|first\s*guess)\s*(admin|staff|support|official|moderator)$/i;

function isBlocked(value) {
  const normal = value.normalize("NFKC").toLowerCase()
    .replace(/[@4]/g, "a").replace(/[01357]/g, ch => ({0:"o",1:"i",3:"e",5:"s",7:"t"}[ch]));
  const tokens = normal.match(/[a-z]+/g) || [];
  if (tokens.some(token => words.has(token))) return true;
  // Joined characters defeat spaces/punctuation; restricting to the severe
  // subset avoids indiscriminate substring checks on ordinary place names.
  const compact = normal.replace(/[^a-z]/g, "").replace(/(.)\1{2,}/g, "$1$1");
  if (strongWords.some(word => compact.includes(word))) return true;
  return impersonation.test(value.trim());
}

exports.approvePublicName = onCall({maxInstances: 20}, async request => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in before choosing a name.");
  const scope = request.data?.scope;
  const name = request.data?.name;
  if (!["player", "league"].includes(scope) || typeof name !== "string" ||
      name !== name.trim() || name.length < 2 ||
      name.length > (scope === "player" ? 20 : 28) ||
      !/[a-z0-9]/i.test(name) || isBlocked(name)) {
    throw new HttpsError("invalid-argument", "This name isn't permitted. Please choose another.");
  }
  await db.collection("name_approvals").doc(uid)
    .collection("scopes").doc(scope).set({
      name, approvedAt: FieldValue.serverTimestamp(),
    });
  return {approved: true};
});
