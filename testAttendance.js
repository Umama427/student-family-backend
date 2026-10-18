require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456'; // apna password dalein

const STUDENT_ID = '6ace7dc37c0a13e5c679da24'; // Azka ka studentId (challan response se liya)

const testAttendance = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    const token = loginRes.data.token;
    console.log('✅ Logged in.\n');

    const headers = { Authorization: `Bearer ${token}` };

    console.log('📝 Marking attendance as Present...');
    const markRes = await axios.post(
      `${BASE_URL}/attendance/mark`,
      {
        type: 'student',
        refId: STUDENT_ID,
        status: 'Present',
        remarks: 'Test attendance entry',
      },
      { headers }
    );
    console.log('✅ Attendance marked:', markRes.data);

    console.log('\n📊 Fetching attendance summary...');
    const summaryRes = await axios.get(
      `${BASE_URL}/attendance/summary?type=student&refId=${STUDENT_ID}`,
      { headers }
    );
    console.log('✅ Summary:', summaryRes.data);
  } catch (error) {
    console.error('\n❌ Error:', error.response ? error.response.data : error.message);
  }
};

testAttendance();