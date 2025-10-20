#!/usr/bin/env node

const fetch = require('node-fetch');

const API_BASE = 'http://localhost:3001';

async function testEmojiStickers() {
  try {
    // First register a test user
    console.log('🔧 Registering test user...');
    const registerResponse = await fetch(`${API_BASE}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'testuser_' + Date.now(),
        email: `test_${Date.now()}@example.com`,
        password: 'password123'
      })
    });

    if (!registerResponse.ok) {
      const error = await registerResponse.text();
      console.log('Registration response:', error);
    }

    // Login to get token
    console.log('🔑 Logging in...');
    const loginResponse = await fetch(`${API_BASE}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'testuser_' + Math.floor(Date.now() / 1000),
        password: 'password123'
      })
    });

    if (!loginResponse.ok) {
      // Try with a different user
      const registerResponse2 = await fetch(`${API_BASE}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: 'testuser2_' + Date.now(),
          email: `test2_${Date.now()}@example.com`,
          password: 'password123'
        })
      });

      const loginResponse2 = await fetch(`${API_BASE}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: 'testuser2_' + Math.floor(Date.now() / 1000),
          password: 'password123'
        })
      });

      if (!loginResponse2.ok) {
        console.error('❌ Login failed');
        return;
      }

      const { token } = await loginResponse2.json();
      
      // Test sending different message types
      console.log('📝 Testing text message...');
      await testMessage(token, { type: 'text', text: 'Hello world!' });

      console.log('😀 Testing emoji message...');
      await testMessage(token, { type: 'emoji', emoji: '😀' });

      console.log('🎉 Testing sticker message...');
      await testMessage(token, { type: 'sticker', sticker: 'party' });

      console.log('✅ All tests completed successfully!');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

async function testMessage(token, messageData) {
  const response = await fetch(`${API_BASE}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(messageData)
  });

  if (response.ok) {
    const result = await response.json();
    console.log(`✅ ${messageData.type} message sent:`, result);
  } else {
    const error = await response.text();
    console.log(`❌ Failed to send ${messageData.type} message:`, error);
  }
}

testEmojiStickers();