require('dotenv').config();
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:5000/api';

// ⚠️ Yahan apna admin email/password dalein
const ADMIN_EMAIL = 'admin@edumanage.com';
const ADMIN_PASSWORD = '123456';

// Challan ID jo aapne diya tha
const CHALLAN_ID = '6ace7dc37c0a13e5c679da25';

const testPdfDownload = async () => {
  try {
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });

    const token = loginRes.data.token;
    console.log('✅ Login successful, token received.\n');

    console.log(`📄 Downloading PDF for challan: ${CHALLAN_ID}...`);
    const pdfRes = await axios.get(`${BASE_URL}/challans/${CHALLAN_ID}/pdf`, {
      headers: { Authorization: `Bearer ${token}` },
      responseType: 'arraybuffer',
    });

    const filePath = path.join(__dirname, 'test-challan.pdf');
    fs.writeFileSync(filePath, pdfRes.data);

    console.log(`\n✅ PDF saved successfully at: ${filePath}`);
    console.log('👉 Ab is file ko double-click karke kholein.');
  } catch (error) {
    console.error('\n❌ Error occurred:');
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      try {
        const errorText = Buffer.from(error.response.data).toString('utf-8');
        console.error(`   Message: ${errorText}`);
      } catch {
        console.error(`   Message:`, error.response.data);
      }
    } else {
      console.error(error.message);
    }
  }
};

testPdfDownload();