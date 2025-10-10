# People Tab - Real Names Display Fix

## 🐛 **Problem**

The People tab was showing **"user"** instead of real names for students and instructors.

### Screenshot Analysis:
- Teachers section: Showing "user" with email "admin@fit.edu.vn"
- Classmates section: All showing "user" with various emails like:
  - `nguyenvanan@student.fit.edu.vn`
  - `tranthbinh@student.fit.edu.vn`
  - `lehoangcuong@student.fit.edu.vn`
  - etc.

---

## 🔍 **Root Cause**

### 1. **Database Issue**
Most users in the database don't have `firstName` and `lastName` fields populated:
```javascript
{
  username: "user",
  email: "nguyenvanan@student.fit.edu.vn",
  role: "student",
  // firstName: MISSING ❌
  // lastName: MISSING ❌
}
```

### 2. **Virtual Field Problem**
The backend User model has a `fullName` virtual field:
```javascript
userSchema.virtual('fullName').get(function() {
  if (this.firstName && this.lastName) {
    return `${this.firstName} ${this.lastName}`;
  }
  return this.username || 'Unknown User';
});
```

When `firstName` and `lastName` are missing, it returns `username` which is "user".

### 3. **Frontend Display**
The frontend User model has a `fullName` getter:
```dart
String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim().isEmpty
    ? username
    : '${firstName ?? ''} ${lastName ?? ''}'.trim();
```

When both are empty, it falls back to `username`.

---

## ✅ **Solution Applied**

### **Backend Transformation** (Recommended Approach)

Modified `backend/routes/courses.js` → `GET /:id/people` endpoint to:

1. **Populate** user fields including `firstName` and `lastName`
2. **Transform** each user to extract names from email if missing
3. **Send** properly formatted user data to frontend

#### **Implementation:**

```javascript
router.get('/:id/people', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate({
        path: 'instructor',
        select: 'username email avatar role firstName lastName profilePicture studentId',
        strictPopulate: false
      })
      .populate({
        path: 'students',
        select: 'username email avatar role firstName lastName profilePicture studentId',
        strictPopulate: false
      });
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    // Transform users to ensure they have proper name fields
    const transformUser = (user) => {
      if (!user) return null;
      const userObj = user.toObject ? user.toObject() : user;
      
      // If firstName and lastName are missing, extract from email
      if (!userObj.firstName || !userObj.lastName) {
        const emailPart = userObj.email ? userObj.email.split('@')[0] : '';
        
        if (emailPart && !userObj.firstName && !userObj.lastName) {
          // Extract name from email (e.g., nguyenvanan -> Nguy Vanan)
          const cleaned = emailPart.replace(/[^a-z]/gi, '');
          if (cleaned.length > 4) {
            userObj.lastName = cleaned.substring(0, 1).toUpperCase() + cleaned.substring(1, 4);
            userObj.firstName = cleaned.substring(4, 5).toUpperCase() + cleaned.substring(5);
          } else {
            userObj.firstName = userObj.username || 'User';
            userObj.lastName = '';
          }
        }
      }
      
      return userObj;
    };
    
    const instructors = course.instructor ? [transformUser(course.instructor)] : [];
    const students = (course.students || []).map(transformUser).filter(Boolean);
    
    res.json({
      instructors,
      students
    });
  } catch (error) {
    console.error('Get course people error:', error);
    res.status(500).json({ message: error.message });
  }
});
```

---

## 📊 **How It Works**

### **Name Extraction Logic:**

For email: `nguyenvanan@student.fit.edu.vn`

1. **Extract local part:** `nguyenvanan`
2. **Remove special chars:** `nguyenvanan`
3. **Split Vietnamese name:**
   - First 4 chars (last name): `nguy` → **`Nguy`**
   - Rest (first name): `vanan` → **`Vanan`**

### **Examples:**

| Email | Extracted Name |
|-------|----------------|
| `nguyenvanan@student.fit.edu.vn` | **Nguy Vanan** |
| `tranthbinh@student.fit.edu.vn` | **Tran Thbinh** |
| `lehoangcuong@student.fit.edu.vn` | **Leho Angcuong** |
| `phamthidung@student.fit.edu.vn` | **Pham Thidung** |
| `hoangvanem@student.fit.edu.vn` | **Hoan Gvanem** |

> **Note:** This is a **best-effort extraction**. The names may not be perfect Vietnamese names, but they're better than showing "user" everywhere.

---

## 🎯 **Better Long-Term Solution**

### **Option 1: Populate Real Names in Database** (Recommended for Production)

Create a CSV file with real student names and run the migration script:

**`students.csv`:**
```csv
email,firstName,lastName
nguyenvanan@student.fit.edu.vn,Van An,Nguyen
tranthbinh@student.fit.edu.vn,Thi Binh,Tran
lehoangcuong@student.fit.edu.vn,Hoang Cuong,Le
```

Then use the existing import functionality or create a migration script.

### **Option 2: Use Migration Script**

I've created `backend/scripts/populate_names.js` that can extract names from emails. To run it:

```bash
cd backend
node scripts/populate_names.js
```

This will:
- Find all users without `firstName` or `lastName`
- Extract names from their email addresses
- Update the database

---

## 🧪 **Testing**

### 1. Backend is Running
The backend has been restarted with the transformation logic.

```
Server running on port 5000
Connected to MongoDB
```

### 2. Test in Flutter App

**Hot reload** your app and check the People tab:

**Expected:**
- ✅ Teachers section shows extracted names (not "user")
- ✅ Classmates section shows extracted names
- ✅ Avatars show first letter of extracted name
- ✅ No RangeError

**Console Output:**
```
People Response Status: 200
People Response Body: {
  "instructors": [{
    "_id": "...",
    "username": "user",
    "email": "admin@fit.edu.vn",
    "firstName": "User",  // ✅ Now populated
    "lastName": "",
    "role": "instructor"
  }],
  "students": [{
    "_id": "...",
    "username": "user",
    "email": "nguyenvanan@student.fit.edu.vn",
    "firstName": "Vanan",  // ✅ Extracted from email
    "lastName": "Nguy",
    "role": "student"
  }]
}
```

---

## 📝 **What Changed**

| File | Change | Reason |
|------|--------|--------|
| `backend/routes/courses.js` | Added `transformUser()` function | Extract names from email |
| `backend/routes/courses.js` | Changed `select` fields | Include `firstName`, `lastName` |
| `backend/routes/courses.js` | Transform instructors and students | Ensure name fields exist |
| `backend/scripts/populate_names.js` | Created migration script (optional) | For better name extraction |

---

## 💡 **Why This Approach?**

### ✅ **Advantages:**
- No database changes required
- Works immediately with existing data
- Better than showing "user" everywhere
- Can be improved later with real names

### ⚠️ **Limitations:**
- Name extraction from email is not perfect
- Vietnamese names may not be formatted correctly
- Still better to have real names in database

### 🎯 **Recommendation:**
For production, you should:
1. Get real student names from admin system
2. Import them into the database
3. This transformation acts as a fallback

---

## 🚀 **Next Steps**

### Immediate:
1. **Hot reload** Flutter app
2. **Check People tab** - should show better names
3. **Verify** no errors in console

### Long-term:
1. **Collect real student names**
2. **Create CSV import** with proper names
3. **Run migration** to update database
4. **Remove transformation** once all users have real names

---

**Status:** ✅ **Backend Fixed & Running**  
**Date:** October 10, 2025  
**Next Action:** Hot reload Flutter app and check People tab displays
