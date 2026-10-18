require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456'; // apna password dalein

const testBulkAttendance = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };
    console.log('✅ Logged in.\n');

    // Pehle kuch students fetch karte hain
    console.log('📋 Fetching students...');
    const studentsRes = await axios.get(`${BASE_URL}/students`, { headers });
    const students = studentsRes.data.data.slice(0, 5); // pehle 5 students lein
    console.log(`✅ Found ${students.length} students for testing.\n`);

    // Bulk attendance records banate hain
    const records = students.map((s, index) => ({
      refId: s._id,
      status: index % 3 === 0 ? 'Absent' : 'Present', // har 3rd student absent
      remarks: '',
    }));

    console.log('📝 Marking bulk attendance...');
    const bulkRes = await axios.post(
      `${BASE_URL}/attendance/bulk-mark`,
      {
        type: 'student',
        date: new Date().toISOString(),
        records,
      },
      { headers }
    );
    console.log('✅ Bulk attendance result:', bulkRes.data);

    // Verify karte hain
    console.log('\n📊 Fetching today\'s attendance records...');
    const todayRes = await axios.get(`${BASE_URL}/attendance?type=student`, { headers });
    console.log(`✅ Total attendance records found: ${todayRes.data.count}`);
    todayRes.data.data.slice(0, 5).forEach((r) => {
      console.log(`   - ${r.refId?.fullName || r.refId} : ${r.status}`);
    });
  } catch (error) {
    console.error('\n❌ Error:', error.response ? error.response.data : error.message);
  }
};

testBulkAttendance();