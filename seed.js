require('dotenv').config();
const mongoose = require('mongoose');
const Family = require('./models/Family');
const Student = require('./models/Student');
const connectDB = require('./config/db');

// ⚠️ IMPORTANT: Apne models/Student.js mein gender enum check karein
// Agar wahan 'Male'/'Female' hai to GENDER_MALE/GENDER_FEMALE ko waisे set karein
const GENDER_MALE = 'male';
const GENDER_FEMALE = 'female';

const semesterData = {
  1: ["Muhammad Dawood Khan","Ayan Atique","Muhammad Raza","Umail Ansari","Uzair Rao","Wahaj Ahmed","Rao Abdul Samad","Muhammad Kashan","Zaid Ahmed","Syeda Zainab Hina","Abdul Moiz","Fizza","Syed Aku Asaad","Muhammad Hassan Karim Khan","Amna","Umme Hani","Hafsa Jawaid","Syeda Vershia Batool Zaidi","Abdul Basit","Hozan Ahmed","Muntaha Shoukat","Hammad Hayee","Karam Ali Afaque","Abdul Rehman","Nehal Fatima","Jahangir Ahmed","Muhammad Uddin","Mudassir Ali","Aayaan Baloch","Amanullah","Tayyab Adnan Ghouri","Muhammad Rohan","Muhammad Abbas Ali Shah","Abdul Rafay","Masroor Khan","Goutam","Hira Kousar","Manahil Aziz","Muhammad Talha","Mandeep Kumar","Laiba Anjum","Eman Waseem Uddin","Abdul Adil","Basil Gohar","Laiba Aamir","Syed Abdul Sami","Kartar","Syed Hashir Ali","Zunaib Khan","Muhammad Rehan","Laraib","Mirza Shehryar Baig Mughal","Muhammad Zaid","Waqar Ali"],
  2: ["Abdul Raafay Bin Aamir","Adeeba","Aiza Ashfaque Qureshi","Atif Khan","Baby Azmat","Fiza","Hania Ali","Imam Ud Din","Makhdoom Ayan Hussain","Maria Khan","Muhammad Usaid Siddiqui","Shakir Hussain","Summaiya Ali","Syed Murtaza Ahmed","Syed Rahim Abbas","Syed Yashar Ali","Syeda Rudabey","Wijdan","Yousuf Ahmed Khan","Zain Ul Abideen","Zindagi Ali","Abdul Hakeem","Arslan Narai","Ayan Rehman","Ayesha Nasir Shaikh","Daniya","Fiza Fatima Siddique","Hashir Ali","Laraib Fatima","Muhammad Anas","Muhammad Asad Khan","Muhammad Ayan","Muhammad Hasnain Ali Shah","Muhammad Irtaza","Muhammad Murtaza","Muhammad Muzzammil","Muhammad Rehan Baig","Muskan Ahmed","Muskan Ali","Rao Asad Ahmed","Rawaha Nadeem","Sharjeel Ali","Syed Ahmed Ali","Jamal Ud Din"],
  3: ["Abdul Nabi","Abdul Rehman Khan","Abiha","Agha Muhammad Daim Nabi","Alishba Sultana","Alishbah Kashif Chishti","Alyaan Naveed","Anabia Rashid","Bilal Raza","Dua Malka Talpur","Eman Bibi","Faiza","Hamza Aasim Chishti","Haseeb Ahmed","Ijlal Hyder","Junaid Hussain Minhas","Komal","Laiba","Meer Muhammad","Mehtab Ul Haq","Mirza Athar Baig","Mishraz Ahmed Tahir","Moosa Muhammad Ali","Muhammad Ahsan","Muhammad Bilal Khan","Muhammad Hammad","Muhammad Muneeb Khan","Neha Noor","Sadia Naveed","Salman Ali","Shah Zaman","Sibtain Raza","Sufiyan","Syed Muntazir Mehdi Jafry","Tanveer Ali","Urooj Fatima","Wajiha Shoukat","Yashfa Zaidi"],
  4: ["Abdul Hadi","Ali Raza","Aroosha Sikandar","Bilal Ahmed Mir","Hassan Ahmed","Hafsa Noor","Iman Fatima","Jawad Ul Haq","Moiz Farhan Vohra","Muhammad Gulzaib Khan","Muhammad Hasnain Baig","Muhammad Owais","Muhammad Rohan Siddiqui","Muhammad Uzair Khan","Muhammad Yashfain Aamir","Murtaza Shaikh","Mussadique Jatoi","Syed Abdul Moiz","Syed Hassan Ahmed","Zunaira Jawaid","Aamna Siddiqui","Abdullah Khan","Abeeha Batool","Furqan Haider","Fuzail Bin Abid","Herman Bibi","Manahil Jahangir","Muhammad Hassan","Muhammad Mohsin","Muhammad Rafi","Noor Ul Huda","Rida Fatima Siddiqui","Rubaisha Khan","Sarang Raza","Sumeia Naveed","Syed Usaid Ali","Wania Khan"],
  5: ["Abdul Kabeer","Abdullah Arain","Affan Ahmed","Akram Nawaz","Arjeena Nawaz","Bisma Khan","Hafsa Amna","Inayat Ali","Irfan Ahmed Khan","Jeejal Iqbal","Muhammad Ahmed Hassan","Muhammad Ali Sadiq","Muhammad Haris Arain","Muhammad Tariq","Sania Khoso","Syed Wajih Uddin","Syed Farzain Ali Jaffri","Tanzeela Khan","Umama Nadeem","Vishal Das","Wazir Ali","Zainab Jawaid","Anosh Naqvi","Moomal Khair Ul Nisa"],
  6: ["Ahmed Raza","Aleena Syed","Alina Khan","Aryan Ali Khan","Haseebullah Khan","Hassam Farooqui","Kinza Fatima","Muhammad Ahraz Faisal","Muhammad Ismail","Muhammad Kaif","Muhammad Moiz","Muhammad Tilmeez","Muhammad Umar","Payal Kumari","Qazi Muhammad Ashhal","Sobia Iqbal","Urooba Naz","Shafique Rahman","Hamad Ali","Abdul Waheed","Eliza Yasim Ali","Bhawna Kumari","Fizza Siddiqui","Mahira Khan","Noor Ul Saba","Sheharyar Ahmed","Syeda Anusha Rizvi","Abdullah Shaikh","Qamar Un Nisa","Syed Azhan Ali Zaidi","Syeda Shantul Zehra"],
  7: ["Abdullah Baloch","Agha Hifza Mushtaque","Ahsan Matloob Ahmed","Aina Naz","Amna Afridi","Areeba Khan","Ehsan Jamal","Fatima Abrar","Harmain Khan","Hiba Farhan","Jadam Khan","Kanwal Fatima","Maryam Khan","Memona Ali","Muhammad Azam Ansari","Muhammad Haris","Muhammad Shahzil","Muhammad Umair","Muhammad Zaryab Siddiqui","Rida Mughal","Sualeha Muneer","Syed Shaheer Ali","Syed Talal Shah"],
  8: ["Agha Mouiz Ahmed","Jamal E Waris Khan","Maryam Tahir","Mirza Umar Baig","Muhammad Hassan Shaikh","Syed Usman Ali Shah","Tayyaba Tahir","Fatima Zafar","Abdul Sameer Rajput"],
};

const randomPhone = () => `03${Math.floor(100000000 + Math.random() * 899999999)}`.slice(0,11);
const classNames = { 1:"BSCS-1st",2:"BSCS-2nd",3:"BSCS-3rd",4:"BSCS-4th",5:"BSCS-5th",6:"BSCS-6th",7:"BSCS-7th",8:"BSCS-8th" };

const seedDatabase = async () => {
  await connectDB();
  console.log('🌱 Seeding started...');

  // Purana test data clean karna chahte hain to uncomment karein:
  // await Student.deleteMany({});
  // await Family.deleteMany({});

  let totalFamilies = 0;
  let totalStudents = 0;
  let failedStudents = 0;

  for (const semester of Object.keys(semesterData)) {
    const names = semesterData[semester];

    for (let i = 0; i < names.length; i += 2) {
      const groupNames = names.slice(i, i + 2);
      const familyCode = `FAM-S${semester}-${Math.floor(i / 2) + 1}-${Date.now()}${Math.floor(Math.random()*1000)}`;
      const primaryPhone = randomPhone();

      let family;
      try {
        family = await Family.create({
          familyName: `${groupNames[0].split(' ')[0]} Family`,
          familyCode,
          fatherName: `Mr. ${groupNames[0].split(' ')[0]} Sr.`,
          primaryPhone,
          address: 'Hyderabad, Sindh',
        });
        totalFamilies++;
      } catch (err) {
        console.error(`⚠️ Family creation failed for ${familyCode}:`, err.message);
        continue;
      }

      let order = 1;
      for (const fullName of groupNames) {
        try {
          await Student.create({
            familyId: family._id,
            fullName,
            className: classNames[semester],
            gender: order % 2 === 0 ? GENDER_FEMALE : GENDER_MALE,
            siblingOrder: order,
            discountPercentage: order === 2 ? 10 : 0,
            monthlyTuitionFee: 3000 + Number(semester) * 500,
            status: 'active',
          });
          totalStudents++;
        } catch (err) {
          failedStudents++;
          console.error(`⚠️ Skipped student "${fullName}":`, err.message);
        }
        order++;
      }
    }
  }

  console.log(`\n✅ Seeding complete!`);
  console.log(`   Families created: ${totalFamilies}`);
  console.log(`   Students created: ${totalStudents}`);
  if (failedStudents > 0) console.log(`   ⚠️ Students skipped (errors): ${failedStudents}`);

  mongoose.connection.close();
};

seedDatabase().catch((err) => {
  console.error('❌ Seeding failed completely:', err);
  mongoose.connection.close();
});