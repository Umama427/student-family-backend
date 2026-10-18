require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456'; // apna password dalein

const testPenalty = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };
    console.log('✅ Logged in.\n');

    // Pehle overdue challans dekhte hain penalty lagane se pehle
    console.log('📋 Checking overdue challans BEFORE penalty...');
    const beforeRes = await axios.get(`${BASE_URL}/challans?status=Overdue`, { headers });
    console.log(`✅ Found ${beforeRes.data.count} overdue challans.\n`);

    if (beforeRes.data.count > 0) {
      const sample = beforeRes.data.data[0];
      console.log(`   Sample BEFORE: ${sample.studentId?.fullName} | Total Payable: ${sample.totalPayable} | Penalty: ${sample.penaltyAmount}`);
    }

    // Ab penalty apply karte hain (Rs. 500 default)
    console.log('\n💰 Applying penalty (Rs. 500) on all overdue challans...');
    const penaltyRes = await axios.post(
      `${BASE_URL}/challans/apply-penalty`,
      { penaltyAmount: 500 },
      { headers }
    );
    console.log('✅ Penalty result:', penaltyRes.data);

    // Verify karte hain penalty lagne ke baad
    console.log('\n📋 Checking overdue challans AFTER penalty...');
    const afterRes = await axios.get(`${BASE_URL}/challans?status=Overdue`, { headers });
    if (afterRes.data.count > 0) {
      const sample = afterRes.data.data[0];
      console.log(`   Sample AFTER: ${sample.studentId?.fullName} | Total Payable: ${sample.totalPayable} | Penalty: ${sample.penaltyAmount}`);
    }
  } catch (error) {
    console.error('\n❌ Error:', error.response ? error.response.data : error.message);
  }
};

testPenalty();