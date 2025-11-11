// utils/agoraToken.js
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// Agora credentials
const APP_ID = 'afa109d795eb450db1793f9f0b5f0ec9';
const APP_CERTIFICATE = 'ca04017022db42a48745e123b3c009b8';

/**
 * Generate Agora RTC token
 * @param {string} channelName - Channel name
 * @param {number} uid - User ID (0 for auto-generated)
 * @param {string} role - 'publisher' or 'subscriber'
 * @param {number} expirationTimeInSeconds - Token expiration time (default: 3600)
 * @returns {string} RTC token
 */
function generateRtcToken(channelName, uid = 0, role = 'publisher', expirationTimeInSeconds = 3600) {
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  // Convert role string to RtcRole
  const rtcRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  // Build token
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    rtcRole,
    privilegeExpiredTs
  );

  return token;
}

module.exports = {
  generateRtcToken
};
