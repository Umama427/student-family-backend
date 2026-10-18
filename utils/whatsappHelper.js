// Helper function to clean phone number (remove spaces, dashes, leading 0)
const formatPhoneNumber = (phone) => {
  let cleaned = phone.replace(/[^0-9]/g, ''); // sirf numbers rakho
  
  // Agar number 0 se start ho raha hai (e.g., 03001234567), to Pakistan code (92) laga dein
  if (cleaned.startsWith('0')) {
    cleaned = '92' + cleaned.substring(1);
  }
  return cleaned;
};

// Generate WhatsApp deep link
const generateWhatsAppLink = (phone, message) => {
  const formattedPhone = formatPhoneNumber(phone);
  const encodedMessage = encodeURIComponent(message);
  return `https://wa.me/${formattedPhone}?text=${encodedMessage}`;
};

// Message Templates
const messageTemplates = {
  feeReminder: (data) => {
    return `Dear ${data.guardianName},\n\nYeh ek dosti bhara reminder hai ke *${data.studentName}* (Roll No: ${data.rollNumber}) ki fee abhi tak pending hai.\n\n📋 Challan No: ${data.challanNumber}\n💰 Amount Due: Rs. ${data.amount}\n📅 Due Date: ${data.dueDate}\n\nBraye meherbani jald az jald fee jama karwa dein. Shukriya!\n\n- Student & Family Management System`;
  },

  paymentConfirmation: (data) => {
    return `Dear ${data.guardianName},\n\nAapki fee payment kamyabi se wasool ho gayi hai! ✅\n\n📋 Receipt No: ${data.receiptNumber}\n👤 Student: ${data.studentName}\n💰 Amount Paid: Rs. ${data.amount}\n📅 Payment Date: ${data.paymentDate}\n\nShukriya aapke waqt par payment ke liye!\n\n- Student & Family Management System`;
  },

  emergencyAnnouncement: (data) => {
    return `🚨 *Emergency Announcement*\n\nDear Parents,\n\n${data.message}\n\nBraye meherbani is maamle ko sanjeedgi se len.\n\n- Student & Family Management System`;
  },

  generalAnnouncement: (data) => {
    return `📢 *Announcement*\n\nDear ${data.guardianName},\n\n${data.message}\n\n- Student & Family Management System`;
  }
};

module.exports = { generateWhatsAppLink, formatPhoneNumber, messageTemplates };