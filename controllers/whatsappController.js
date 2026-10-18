const FeeChallan = require('../models/FeeChallan');
const Student = require('../models/Student');
const Family = require('../models/Family');
const Salary = require('../models/Salary');
const { generateWhatsAppLink, messageTemplates } = require('../utils/whatsappHelper');

// @desc Generate Fee Reminder WhatsApp link for a specific challan
exports.getFeeReminderLink = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.challanId)
      .populate('studentId')
      .populate('familyId');

    if (!challan) {
      return res.status(404).json({ message: 'Challan not found' });
    }

    const data = {
      guardianName: challan.familyId.fatherName, // ✅ FIXED
      studentName: challan.studentId.fullName,
      rollNumber: challan.studentId.rollNumber,
      challanNumber: challan.challanNumber,
      amount: challan.totalPayable,
      dueDate: new Date(challan.dueDate).toDateString()
    };

    const message = messageTemplates.feeReminder(data);
    const link = generateWhatsAppLink(challan.familyId.primaryPhone, message);

    res.status(200).json({ link, message, phone: challan.familyId.primaryPhone });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc Generate Payment Confirmation WhatsApp link
exports.getPaymentConfirmationLink = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.challanId)
      .populate('studentId')
      .populate('familyId');

    if (!challan) {
      return res.status(404).json({ message: 'Challan not found' });
    }

    const data = {
      guardianName: challan.familyId.fatherName, // ✅ FIXED
      studentName: challan.studentId.fullName,
      receiptNumber: `RCPT-${challan.challanNumber}`,
      amount: challan.paidAmount,
      paymentDate: challan.paidDate ? new Date(challan.paidDate).toDateString() : new Date().toDateString()
    };

    const message = messageTemplates.paymentConfirmation(data);
    const link = generateWhatsAppLink(challan.familyId.primaryPhone, message);

    res.status(200).json({ link, message, phone: challan.familyId.primaryPhone });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc Generate Emergency/General Announcement link for a specific family
exports.getAnnouncementLink = async (req, res) => {
  try {
    const { message, type } = req.body;
    const family = await Family.findById(req.params.familyId);

    if (!family) {
      return res.status(404).json({ message: 'Family not found' });
    }

    const data = { 
      guardianName: family.fatherName, // ✅ FIXED
      message 
    };
    const finalMessage = type === 'emergency' 
      ? messageTemplates.emergencyAnnouncement(data)
      : messageTemplates.generalAnnouncement(data);

    const link = generateWhatsAppLink(family.primaryPhone, finalMessage);

    res.status(200).json({ link, message: finalMessage, phone: family.primaryPhone });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc Bulk announcement links for ALL families
exports.getBulkAnnouncementLinks = async (req, res) => {
  try {
    const { message, type } = req.body;
    const families = await Family.find();

    const links = families.map((family) => {
      const data = { 
        guardianName: family.fatherName, // ✅ FIXED
        message 
      };
      const finalMessage = type === 'emergency'
        ? messageTemplates.emergencyAnnouncement(data)
        : messageTemplates.generalAnnouncement(data);

      return {
        familyName: family.familyName,
        guardianName: family.fatherName, // ✅ FIXED
        phone: family.primaryPhone,
        link: generateWhatsAppLink(family.primaryPhone, finalMessage)
      };
    });

    res.status(200).json({ totalFamilies: links.length, links });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc Generate Salary Slip WhatsApp link for staff
// @route GET /api/whatsapp/salary/:salaryId
exports.getSalaryWhatsAppLink = async (req, res) => {
  try {
    const salary = await Salary.findById(req.params.salaryId).populate('staffId');

    if (!salary) {
      return res.status(404).json({ message: 'Salary record not found' });
    }

    const staff = salary.staffId;
    if (!staff) {
      return res.status(404).json({ message: 'Staff member not found for this salary record' });
    }

    const message = `Assalam-o-Alaikum ${staff.fullName},\n\nAapki salary slip:\nMonth: ${salary.month}/${salary.year}\nBase Salary: Rs. ${salary.baseSalary}\nBonus: Rs. ${salary.bonus || 0}\nDeductions: Rs. ${salary.deductions || 0}\nNet Salary: Rs. ${salary.netSalary}\nStatus: ${salary.status}\n\nShukriya.`;

    const phone = staff.phone || staff.phoneNumber || '';
    if (!phone) {
      return res.status(400).json({ message: 'Staff phone number not available' });
    }

    const link = generateWhatsAppLink(phone, message);

    res.status(200).json({ link, message, phone });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};