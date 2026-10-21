const {
  requestAccountDeletion,
  getAccountDeletionStatus,
  resumeAccountDeletions
} = require("./account_deletion");

exports.requestAccountDeletion = requestAccountDeletion;
exports.getAccountDeletionStatus = getAccountDeletionStatus;
exports.resumeAccountDeletions = resumeAccountDeletions;

// Public-name moderation; existing account-deletion exports remain untouched.
exports.approvePublicName = require('./public_name_moderation').approvePublicName;
