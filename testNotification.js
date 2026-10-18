require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456'; // apna actual password dalein

const testNotification = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };
    console.log('✅ Logged in.\n');

    console.log('📢 Creating a notification...');
    const createRes = await axios.post(
      `${BASE_URL}/notifications`,
      {
        title: 'Fee Due Reminder',
        message: 'Dear parents, October month fee is due by 25th. Please pay on time.',
        type: 'fee',
        audience: 'families',
      },
      { headers }
    );
    console.log('✅ Notification created:', createRes.data);

    console.log('\n📋 Fetching all notifications...');
    const listRes = await axios.get(`${BASE_URL}/notifications`, { headers });
    console.log(`✅ Found ${listRes.data.count} notifications.`);
    listRes.data.data.forEach((n) => console.log(`   - [${n.type}] ${n.title}`));
  } catch (error) {
    console.error('\n❌ Error:', error.response ? error.response.data : error.message);
  }
};

testNotification();