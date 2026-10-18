require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456'; // apna password dalein

const testSalaryWhatsApp = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    const token = loginRes.data.token;
    const headers = { Authorization: `Bearer ${token}` };
    console.log('✅ Logged in.\n');

    console.log('📋 Fetching salary records...');
    const salariesRes = await axios.get(`${BASE_URL}/salaries`, { headers });

    if (!salariesRes.data.data || salariesRes.data.data.length === 0) {
      console.log('⚠️ No salary records found.\n');
      console.log('👉 Creating a sample salary record first...\n');

      // Pehle ek staff fetch karte hain
      const staffRes = await axios.get(`${BASE_URL}/staff`, { headers });
      if (!staffRes.data.data || staffRes.data.data.length === 0) {
        console.log('❌ No staff members found either. Please create a staff member first.');
        return;
      }

      const sampleStaff = staffRes.data.data[0];
      console.log(`✅ Using staff: ${sampleStaff.fullName}`);

      const createSalaryRes = await axios.post(
        `${BASE_URL}/salaries`,
        {
          staffId: sampleStaff._id,
          month: new Date().getMonth() + 1,
          year: new Date().getFullYear(),
          baseSalary: sampleStaff.baseSalary || sampleStaff.basicSalary || 30000,
          bonus: 2000,
          deductions: 500,
          status: 'Paid',
          paymentMethod: 'Cash',
        },
        { headers }
      );
      console.log('✅ Salary record created:', createSalaryRes.data.data._id);

      // Ab usi salary ka WhatsApp link generate karte hain
      const salaryId = createSalaryRes.data.data._id;
      console.log('\n📱 Generating WhatsApp link...');
      const linkRes = await axios.get(`${BASE_URL}/whatsapp/salary/${salaryId}`, { headers });
      console.log('✅ WhatsApp Link:', linkRes.data.link);
      console.log('\n📝 Message Preview:\n', linkRes.data.message);
      return;
    }

    const sampleSalary = salariesRes.data.data[0];
    console.log(`✅ Using existing salary record: ${sampleSalary.staffName} | ${sampleSalary._id}\n`);

    console.log('📱 Generating WhatsApp link...');
    const linkRes = await axios.get(`${BASE_URL}/whatsapp/salary/${sampleSalary._id}`, { headers });
    console.log('✅ WhatsApp Link:', linkRes.data.link);
    console.log('\n📝 Message Preview:\n', linkRes.data.message);
  } catch (error) {
    console.error('\n❌ Error:', error.response ? error.response.data : error.message);
  }
};

testSalaryWhatsApp();