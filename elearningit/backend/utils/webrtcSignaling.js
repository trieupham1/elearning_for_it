// utils/webrtcSignaling.js
const Call = require('../models/Call');

// Store active socket connections: userId -> socketId
const userSockets = new Map();
let ioInstance = null;

// Export function to get io instance and userSockets
const getIO = () => ioInstance;
const getUserSockets = () => userSockets;

module.exports = (io) => {
  ioInstance = io; // Store io instance for use in other modules
  
  io.on('connection', (socket) => {
    console.log('🔌 Socket connected:', socket.id);

    // User registers their socket
    socket.on('register', (userId) => {
      userSockets.set(userId, socket.id);
      socket.userId = userId;
      console.log(`✅ User ${userId} registered with socket ${socket.id}`);
      console.log(`📊 Total registered users: ${userSockets.size}`);
      console.log(`📋 All registered user IDs:`, Array.from(userSockets.keys()));
    });

    // Group video call events
    socket.on('join_group_call', (data) => {
      const { channelName, userId, userName, userProfile } = data;
      socket.join(channelName);
      socket.currentChannel = channelName;
      socket.userId = userId;
      console.log(`👥 ${userName} joined group call: ${channelName}`);
      
      // Get all sockets in this room to send existing participants
      const socketsInRoom = io.sockets.adapter.rooms.get(channelName);
      const existingParticipants = [];
      
      if (socketsInRoom) {
        socketsInRoom.forEach((socketId) => {
          const participantSocket = io.sockets.sockets.get(socketId);
          if (participantSocket && participantSocket.userId && socketId !== socket.id) {
            existingParticipants.push({
              userId: participantSocket.userId,
              userName: participantSocket.userName,
              userProfile: participantSocket.userProfile,
              agoraUid: participantSocket.agoraUid,
            });
          }
        });
      }
      
      // Store user info on socket
      socket.userName = userName;
      socket.userProfile = userProfile;
      
      // Send existing participants to the new joiner
      socket.emit('existing_participants', { participants: existingParticipants });
      
      // Notify others in the room about new user
      socket.to(channelName).emit('user_joined_call', {
        userId,
        userName,
        userProfile,
        socketId: socket.id,
      });
    });

    // Broadcast Agora UID mapping
    socket.on('share_agora_uid', (data) => {
      const { channelName, agoraUid, userId } = data;
      console.log(`📡 Received share_agora_uid:`);
      console.log(`   - Channel: ${channelName}`);
      console.log(`   - Agora UID: ${agoraUid} (type: ${typeof agoraUid})`);
      console.log(`   - User ID: ${userId}`);
      console.log(`   - User Name: ${socket.userName}`);
      console.log(`   - User Profile: ${socket.userProfile}`);
      
      socket.agoraUid = agoraUid;
      
      const mappingData = {
        userId,
        agoraUid,
        userName: socket.userName,
        userProfile: socket.userProfile,
      };
      
      // Broadcast to everyone in the channel including sender
      io.to(channelName).emit('agora_uid_mapped', mappingData);
      console.log(`✅ Broadcasted agora_uid_mapped to channel ${channelName}`);
      console.log(`   Mapping data:`, mappingData);
    });

    socket.on('leave_group_call', (data) => {
      const { channelName, userId } = data;
      if (channelName) {
        socket.leave(channelName);
        socket.to(channelName).emit('user_left_call', { userId });
        console.log(`👋 User ${userId} left group call: ${channelName}`);
      }
    });

    // Chat messages in group call
    socket.on('send_group_message', (data) => {
      const { channelName, message, senderName, senderId, timestamp } = data;
      // Broadcast to everyone in the channel including sender
      io.to(channelName).emit('new_group_message', {
        message,
        senderName,
        senderId,
        timestamp,
      });
      console.log(`💬 Message in ${channelName} from ${senderName}: ${message}`);
    });

    // User status updates (mic/camera)
    socket.on('update_user_status', (data) => {
      const { channelName, agoraUid, userId, isMuted, isCameraOff } = data;
      socket.to(channelName).emit('user_status_updated', {
        agoraUid,
        userId,
        isMuted,
        isCameraOff,
      });
      console.log(`🔊 User ${userId} (Agora UID: ${agoraUid}) status: muted=${isMuted}, camera=${isCameraOff}`);
    });

    // Screen share status updates
    socket.on('screen_share_status', (data) => {
      const { channelName, agoraUid, isSharing } = data;
      // Broadcast to everyone in the channel including sender
      io.to(channelName).emit('screen_share_status', {
        agoraUid,
        isSharing,
      });
      console.log(`🖥️ User with Agora UID ${agoraUid} ${isSharing ? 'started' : 'stopped'} screen sharing in ${channelName}`);
    });

    // Call initiated - send to callee
    socket.on('call_initiated', async (data) => {
      try {
        const { callId, calleeId, callerName, type, offer } = data;
        
        const calleeSocketId = userSockets.get(calleeId);
        if (calleeSocketId) {
          io.to(calleeSocketId).emit('incoming_call', {
            callId,
            callerId: socket.userId,
            callerName,
            type,
            offer
          });
          console.log(`📞 Call initiated: ${socket.userId} -> ${calleeId}`);
        } else {
          // Callee is offline
          socket.emit('call_failed', { reason: 'User is offline' });
          
          // Update call status to missed
          await Call.findByIdAndUpdate(callId, { 
            status: 'missed',
            endedAt: new Date()
          });
        }
      } catch (error) {
        console.error('Error in call_initiated:', error);
        socket.emit('call_error', { message: error.message });
      }
    });

    // Call accepted - send to caller
    socket.on('call_accepted', async (data) => {
      try {
        const { callId, callerId, answer } = data;
        
        const callerSocketId = userSockets.get(callerId);
        if (callerSocketId) {
          io.to(callerSocketId).emit('call_answered', {
            callId,
            calleeId: socket.userId,
            answer
          });
          console.log(`✅ Call accepted: ${callerId} <- ${socket.userId}`);
        }

        // Update call status
        await Call.findByIdAndUpdate(callId, { 
          status: 'accepted',
          startedAt: new Date()
        });
      } catch (error) {
        console.error('Error in call_accepted:', error);
        socket.emit('call_error', { message: error.message });
      }
    });

    // Call rejected
    socket.on('call_rejected', async (data) => {
      try {
        const { callId, otherUserId } = data;
        
        console.log('📞 Call rejection received:', { callId, otherUserId, rejectBy: socket.userId });
        
        const callerSocketId = userSockets.get(otherUserId);
        if (callerSocketId) {
          io.to(callerSocketId).emit('call_rejected', {
            callId,
            rejectedBy: socket.userId
          });
          console.log(`❌ Call rejected notification sent to caller: ${otherUserId}`);
        } else {
          console.log(`⚠️ Caller ${otherUserId} socket not found`);
        }

        // Update call status
        await Call.findByIdAndUpdate(callId, { 
          status: 'rejected',
          endedAt: new Date()
        });
      } catch (error) {
        console.error('Error in call_rejected:', error);
        socket.emit('call_error', { message: error.message });
      }
    });

    // Call ended
    socket.on('call_ended', async (data) => {
      try {
        const { callId, otherUserId } = data;
        
        const otherSocketId = userSockets.get(otherUserId);
        if (otherSocketId) {
          io.to(otherSocketId).emit('call_ended', {
            callId,
            endedBy: socket.userId
          });
          console.log(`📴 Call ended by ${socket.userId}`);
        }

        // Update call status
        await Call.findByIdAndUpdate(callId, { 
          status: 'ended',
          endedAt: new Date()
        });
      } catch (error) {
        console.error('Error in call_ended:', error);
        socket.emit('call_error', { message: error.message });
      }
    });

    // ICE candidate exchange
    socket.on('ice_candidate', (data) => {
      const { otherUserId, candidate } = data;
      const otherSocketId = userSockets.get(otherUserId);
      
      if (otherSocketId) {
        io.to(otherSocketId).emit('ice_candidate', {
          userId: socket.userId,
          candidate
        });
      }
    });

    // Screen sharing started
    socket.on('screen_share_started', async (data) => {
      try {
        const { callId, otherUserId } = data;
        
        const otherSocketId = userSockets.get(otherUserId);
        if (otherSocketId) {
          io.to(otherSocketId).emit('screen_share_started', {
            userId: socket.userId,
            callId
          });
          console.log(`🖥️ Screen sharing started by ${socket.userId}`);
        }

        // Update call
        await Call.findByIdAndUpdate(callId, {
          isScreenSharing: true,
          screenShareStartedAt: new Date()
        });
      } catch (error) {
        console.error('Error in screen_share_started:', error);
      }
    });

    // Screen sharing stopped
    socket.on('screen_share_stopped', async (data) => {
      try {
        const { callId, otherUserId } = data;
        
        const otherSocketId = userSockets.get(otherUserId);
        if (otherSocketId) {
          io.to(otherSocketId).emit('screen_share_stopped', {
            userId: socket.userId,
            callId
          });
          console.log(`🖥️ Screen sharing stopped by ${socket.userId}`);
        }

        // Update call
        await Call.findByIdAndUpdate(callId, {
          isScreenSharing: false
        });
      } catch (error) {
        console.error('Error in screen_share_stopped:', error);
      }
    });

    // Connection quality update
    socket.on('quality_update', (data) => {
      const { otherUserId, quality } = data;
      const otherSocketId = userSockets.get(otherUserId);
      
      if (otherSocketId) {
        io.to(otherSocketId).emit('quality_update', {
          userId: socket.userId,
          quality
        });
      }
    });

    // Disconnect
    socket.on('disconnect', () => {
      if (socket.userId) {
        userSockets.delete(socket.userId);
        console.log(`🔌 User ${socket.userId} disconnected (socket: ${socket.id})`);
        console.log(`📊 Remaining registered users: ${userSockets.size}`);
        console.log(`📋 Remaining user IDs:`, Array.from(userSockets.keys()));
      } else {
        console.log(`🔌 Socket ${socket.id} disconnected (no userId registered)`);
      }
    });
  });

  return userSockets;
};

// Export helper functions
module.exports.getIO = getIO;
module.exports.getUserSockets = getUserSockets;
