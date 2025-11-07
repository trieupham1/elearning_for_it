// routes/agora.js - Agora Token Generation
const express = require('express');
const router = express.Router();
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// Agora credentials
const AGORA_APP_ID = 'afa109d795eb450db1793f9f0b5f0ec9';
const AGORA_APP_CERTIFICATE = 'ca04017022db42a48745e123b3c009b8';

// Token expiration time (24 hours)
const TOKEN_EXPIRATION_TIME = 24 * 3600;

/**
 * POST /api/agora/generate-token
 * Generate Agora RTC token for voice/video calls
 * 
 * Body:
 * - channelName: string (required) - The channel name for the call
 * - uid: number (optional) - User ID (0 for auto-assign)
 * - role: string (optional) - 'publisher' or 'subscriber' (default: 'publisher')
 */
router.post('/generate-token', async (req, res) => {
  try {
    const { channelName, uid = 0, role = 'publisher' } = req.body;

    if (!channelName) {
      return res.status(400).json({ 
        error: 'Channel name is required' 
      });
    }

    // Determine Agora role
    const agoraRole = role === 'subscriber' 
      ? RtcRole.SUBSCRIBER 
      : RtcRole.PUBLISHER;

    // Calculate privilege expiration timestamp
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTimestamp + TOKEN_EXPIRATION_TIME;

    // Build the token
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      agoraRole,
      privilegeExpireTime
    );

    console.log(`✅ Generated Agora token for channel: ${channelName}, uid: ${uid}`);

    res.json({
      success: true,
      token,
      appId: AGORA_APP_ID,
      channelName,
      uid,
      expiresAt: privilegeExpireTime,
    });

  } catch (error) {
    console.error('❌ Error generating Agora token:', error);
    res.status(500).json({ 
      error: 'Failed to generate token',
      message: error.message 
    });
  }
});

/**
 * POST /api/agora/renew-token
 * Renew an existing Agora RTC token
 * Same parameters as generate-token
 */
router.post('/renew-token', async (req, res) => {
  // Same logic as generate-token
  try {
    const { channelName, uid = 0, role = 'publisher' } = req.body;

    if (!channelName) {
      return res.status(400).json({ 
        error: 'Channel name is required' 
      });
    }

    const agoraRole = role === 'subscriber' 
      ? RtcRole.SUBSCRIBER 
      : RtcRole.PUBLISHER;

    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTimestamp + TOKEN_EXPIRATION_TIME;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      agoraRole,
      privilegeExpireTime
    );

    console.log(`🔄 Renewed Agora token for channel: ${channelName}`);

    res.json({
      success: true,
      token,
      appId: AGORA_APP_ID,
      channelName,
      uid,
      expiresAt: privilegeExpireTime,
    });

  } catch (error) {
    console.error('❌ Error renewing Agora token:', error);
    res.status(500).json({ 
      error: 'Failed to renew token',
      message: error.message 
    });
  }
});

module.exports = router;
