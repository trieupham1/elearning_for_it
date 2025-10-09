# E-Learning System - Data Model & CSV Import Specifications

## Core Entity Relationships

```
Semester (1) ──< (Many) Course (1) ──< (Many) Group (1) ──< (Many) Student
```

### 1. **Semester**
- **Required Fields**: 
  - `code` (String, unique)
  - `name` (String)
- **Purpose**: Top-level container for academic period
- **Example**: 
  - Code: "S1-2025"
  - Name: "Semester 1, Academic Year 2025-2026"

### 2. **Course**
- **Required Fields**:
  - `code` (String, unique)
  - `name` (String)
  - `sessions` (Number: 10 or 15)
  - `semester` (Reference to Semester)
- **Purpose**: Academic course within a semester
- **Example**:
  - Code: "CPM502071"
  - Name: "Cross-Platform Mobile Application Development"
  - Sessions: 15
  - Semester: "S1-2025"

### 3. **Group**
- **Required Fields**:
  - `name` (String)
  - `courseId` (Reference to Course)
- **Business Rule**: Within a course, each student can belong to ONLY ONE group
- **Purpose**: Divide students into manageable sections
- **Example**:
  - Course: "Web Programming & Applications"
  - Groups: "Group 1", "Group 2", "Group 3"

### 4. **Student**
- **Required Fields**:
  - `username` (String, unique)
  - `email` (String, unique)
  - `firstName` (String)
  - `lastName` (String)
  - `studentId` (String, unique)
  - `password` (String - for new accounts only)
- **Workflow**: 
  1. Create student accounts (reusable across semesters)
  2. Assign students to groups within courses

## CSV Import Requirements

### Key Principles

1. **Bulk Import Support**: All entities support CSV upload
2. **Validation & Preview**: System validates before import
3. **Smart Duplicate Handling**: 
   - Existing items are identified and skipped
   - Only new items are imported
   - User sees preview of all items with status
4. **Partial Success**: Import proceeds even with some duplicates
5. **Post-Import Report**: Shows detailed results

### CSV Format Specifications

#### 1. Semester CSV
```csv
Code,Name
S1-2025,Semester 1 - Academic Year 2025-2026
S2-2025,Semester 2 - Academic Year 2025-2026
S3-2025,Summer Semester - Academic Year 2025-2026
```

**Validation**:
- Code must be unique
- Name must not be empty

---

#### 2. Course CSV
```csv
Code,Name,Sessions,SemesterCode
CPM502071,Cross-Platform Mobile Application Development,15,S1-2025
DB502042,Database Management Systems,15,S1-2025
AI502063,Artificial Intelligence,10,S1-2025
```

**Validation**:
- Code must be unique
- Sessions must be exactly 10 or 15
- SemesterCode must reference existing semester

---

#### 3. Group CSV
```csv
Name,CourseCode
Group 1,CPM502071
Group 2,CPM502071
Group 3,CPM502071
Group 1,DB502042
Group 2,DB502042
```

**Validation**:
- CourseCode must reference existing course
- Name can be duplicated across different courses

---

#### 4. Student CSV
```csv
Username,Email,FirstName,LastName,StudentId,Password,Department,PhoneNumber,Year
john_doe,john.doe@fit.edu.vn,John,Doe,STU001,student123,Information Technology,0123456789,1
jane_smith,jane.smith@fit.edu.vn,Jane,Smith,STU002,student123,Information Technology,0987654321,2
bob_wilson,bob.wilson@fit.edu.vn,Bob,Wilson,STU003,student123,Information Technology,0111222333,1
alice_brown,alice.brown@fit.edu.vn,Alice,Brown,STU004,student123,Information Technology,,3
```

**Field Descriptions**:
- `Username` (required): Unique username for login
- `Email` (required): Unique email address (must be valid format)
- `FirstName` (required): Student's first name
- `LastName` (required): Student's last name
- `StudentId` (required): Unique student ID number
- `Password` (optional): Password for new accounts (default: "student123")
- `Department` (optional): Department name (default: "Information Technology")
- `PhoneNumber` (optional): Contact phone number
- `Year` (optional): Academic year level (1-6)

**Validation**:
- Username must be unique globally
- Email must be unique and valid format (contains @)
- StudentId must be unique
- Password only used for NEW accounts (ignored for existing)
- Year must be between 1 and 6 if provided
- Department defaults to "Information Technology" if not provided

**Duplicate Handling Example**:
```
Upload 50 students:
- 30 already exist in database → Status: "Already exists" (skipped)
  - Checks: username, email, OR studentId
  - Shows specific reason (e.g., "Username already exists")
- 20 are new → Status: "Will be added"
- Import proceeds with 20 new students
```

---

#### 5. Student-Group Assignment CSV
```csv
StudentId,GroupName,CourseCode
STU001,Group 1,CPM502071
STU002,Group 1,CPM502071
STU003,Group 2,CPM502071
STU004,Group 2,CPM502071
```

**Business Rules**:
- Each student can only be in ONE group per course
- If student already assigned to a group in that course, assignment fails with error
- StudentId must reference existing student
- GroupName + CourseCode must reference existing group

**Validation**:
- Checks if student already in another group for same course
- Verifies student, group, and course all exist

---

## Import Workflow

### Step 1: Upload CSV
- User clicks "Import from CSV" button
- Selects CSV file from device
- System reads and parses file

### Step 2: Validation & Preview
- System validates each row
- Checks for duplicates against database
- Checks for validation errors
- Displays preview table:

```
Row | Data               | Status          | Message
----|--------------------|-----------------|-----------------
1   | S1-2025, Sem 1...  | Will be added  | -
2   | S2-2025, Sem 2...  | Already exists | Duplicate code
3   | S3-2025, Sum...    | Will be added  | -
```

**Status Colors**:
- 🟢 Green: "Will be added"
- 🟠 Orange: "Already exists" (will skip)
- 🔴 Red: "Error" (validation failed)
- 🔵 Blue: "Will update" (for future update operations)

### Step 3: Statistics Display
```
Total Rows: 50
Will Add: 20
Already Exists: 30
Errors: 0
```

### Step 4: User Confirmation
- User reviews preview
- Clicks "Import X Items" button
- Only valid, non-duplicate items are imported

### Step 5: Post-Import Results
```
✓ Import Complete!

Total Rows: 50
Added: 20
Skipped: 30
Errors: 0
```

---

## UI Components

### Management Screen Structure
Each management screen includes:
1. **List View**: Display existing items
2. **Create Button**: Manual single-item creation form
3. **Import CSV Button**: Bulk import with preview
4. **Edit/Delete Actions**: Per-item actions

### CSV Import Dialog Flow
1. Instructions card with template download
2. File picker button
3. Preview table (if file loaded)
4. Statistics summary
5. Import confirmation button
6. Results screen

---

## Error Handling

### Common Errors
1. **Invalid CSV Format**: Wrong number of columns
2. **Missing Required Fields**: Empty values
3. **Duplicate Keys**: Username, email, studentId, course code
4. **Invalid References**: Semester/Course doesn't exist
5. **Business Rule Violations**: Student already in different group for same course

### Error Messages
- Clear, actionable messages
- Row number reference
- Specific field causing error

---

## Example User Story: New Semester Setup

**Instructor needs to set up Semester 1, 2025-2026 with 3 courses and 150 students**

1. **Create Semester**
   - Manual: Enter "S1-2025", "Semester 1 - AY 2025-2026"
   - OR CSV: Upload 1-row CSV with semester info

2. **Create Courses**
   - CSV Upload: 3 courses with 15 sessions each
   - All reference "S1-2025"

3. **Create Groups**
   - CSV Upload: 9 groups total (3 groups per course)

4. **Import Students**
   - CSV Upload: 150 students
   - System checks database:
     - 80 already exist from previous semesters → Skipped
     - 70 are new → Added
   - Preview shows all 150 with their status
   - Import proceeds with 70 new accounts

5. **Assign Students to Groups**
   - CSV Upload: 150 assignments
   - System validates:
     - No student appears twice for same course
     - All students exist
     - All groups exist
   - Import completes successfully

**Result**: Semester fully set up in 5 steps with bulk operations

---

## Technical Notes

### Frontend (Flutter)
- `csv` package for CSV parsing
- `file_picker` package for file selection
- Reusable `CsvImportDialog<T>` widget
- Type-safe import models for each entity

### Backend (Node.js/MongoDB)
- Bulk insert with conflict handling
- Transaction support for consistency
- Validation middleware
- Detailed error responses with row numbers

### API Endpoints (To Implement)
```
POST /api/semesters/import/preview
POST /api/semesters/import/confirm

POST /api/courses/import/preview
POST /api/courses/import/confirm

POST /api/groups/import/preview
POST /api/groups/import/confirm

POST /api/students/import/preview
POST /api/students/import/confirm

POST /api/student-groups/import/preview
POST /api/student-groups/import/confirm
```

Each endpoint returns:
```json
{
  "success": true,
  "totalRows": 50,
  "preview": [
    {
      "rowNumber": 1,
      "data": { ... },
      "status": "willBeAdded|alreadyExists|error",
      "message": "Optional message"
    }
  ],
  "stats": {
    "willAdd": 20,
    "exists": 30,
    "errors": 0
  }
}
```
