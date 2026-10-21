"use strict";
const MAX_SIGNIN_AGE_SECONDS = 5 * 60;
const CONFIRMATION = "DELETE MY ACCOUNT";
function validateRequest(request, nowSeconds = Math.floor(Date.now() / 1000), options = {}) {
  if (!request || !request.auth || !request.auth.uid) return {ok: false, code: "unauthenticated", message: "Sign-in required"};
  if (!request.data || request.data.confirm !== CONFIRMATION) return {ok: false, code: "invalid-argument", message: "Explicit confirmation required"};
  const authTime = Number(request.auth.token && request.auth.token.auth_time);
  // Anonymous guests cannot reauthenticate once their session becomes old.
  // Permit a stale guest session only when the caller has independently verified
  // against Firebase Auth that this is an unlinked anonymous account.
  const allowStaleGuest = options.verifiedAnonymousGuest === true;
  if (!Number.isFinite(authTime) || authTime > nowSeconds + 30 ||
      (!allowStaleGuest && nowSeconds - authTime > MAX_SIGNIN_AGE_SECONDS)) {
    return {ok: false, code: "failed-precondition", message: "Please sign in again before deleting your account"};
  }
  return {ok: true, uid: request.auth.uid};
}
function chooseSuccessor(members, deletingUid, ownerUid) {
  const remaining = [...new Set(members || [])].filter(uid => uid && uid !== deletingUid).sort();
  return {remaining, nextOwner: remaining.includes(ownerUid) ? ownerUid : (remaining[0] || null)};
}
module.exports = {validateRequest, chooseSuccessor, MAX_SIGNIN_AGE_SECONDS, CONFIRMATION};
