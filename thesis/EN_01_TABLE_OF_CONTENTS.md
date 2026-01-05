# TABLE OF CONTENTS

## FRONT MATTER
- Title Page
- Acknowledgments
- Declaration of Originality
- Abstract (English)
- Abstract (Vietnamese)
- Table of Contents
- List of Figures
- List of Tables
- List of Abbreviations

---

## CHAPTER 1: INTRODUCTION ....................................... 1

### 1.1. RATIONALE .................................................. 1
- 1.1.1. Context and Practical Needs
- 1.1.2. Limitations of Current Solutions
- 1.1.3. Necessity of the Project

### 1.2. RESEARCH OBJECTIVES ....................................... 3
- 1.2.1. General Objective
- 1.2.2. Specific Objectives

### 1.3. RESEARCH SCOPE ............................................. 4
- 1.3.1. Scope of Application
- 1.3.2. User Scope
- 1.3.3. Functional Scope
- 1.3.4. Technical Scope
- 1.3.5. Limitations

### 1.4. RESEARCH METHODOLOGY ...................................... 6
- 1.4.1. Literature Review
- 1.4.2. System Analysis and Design
- 1.4.3. Implementation and Testing
- 1.4.4. Evaluation and Improvement

### 1.5. THESIS STRUCTURE ........................................... 7

---

## CHAPTER 2: LITERATURE REVIEW AND REQUIREMENTS ANALYSIS ..... 9

### 2.1. CURRENT STATE OF E-LEARNING SYSTEMS ..................... 9
- 2.1.1. Global E-Learning Market Overview
- 2.1.2. E-Learning in Vietnam
- 2.1.3. Challenges and Opportunities

### 2.2. ANALYSIS OF EXISTING SOLUTIONS .......................... 11
- 2.2.1. Commercial LMS Platforms
- 2.2.2. Open Source Solutions
- 2.2.3. Comparative Analysis
- 2.2.4. Gaps in Current Solutions

### 2.3. PROPOSED SOLUTION ........................................ 15
- 2.3.1. System Overview
- 2.3.2. Key Features and Innovations
- 2.3.3. Target Users

### 2.4. REQUIREMENTS ANALYSIS ................................... 17
- 2.4.1. Functional Requirements
- 2.4.2. Non-Functional Requirements
- 2.4.3. System Constraints

### 2.5. USE CASE ANALYSIS ........................................ 22
- 2.5.1. Student Use Cases (55 use cases)
- 2.5.2. Instructor Use Cases (54 use cases)
- 2.5.3. Administrator Use Cases (32 use cases)

### 2.6. IMPLEMENTATION PLAN ...................................... 45
- 2.6.1. Development Phases
- 2.6.2. Timeline and Milestones
- 2.6.3. Risk Management

---

## CHAPTER 3: TECHNOLOGY REVIEW ................................. 47

### 3.1. FRONTEND TECHNOLOGY - FLUTTER ........................... 47
- 3.1.1. Overview and Architecture
- 3.1.2. Advantages for Cross-Platform Development
- 3.1.3. Flutter Ecosystem and Packages
- 3.1.4. Performance Characteristics

### 3.2. BACKEND TECHNOLOGY - NODE.JS/EXPRESS .................... 58
- 3.2.1. Node.js Runtime Environment
- 3.2.2. Express Framework
- 3.2.3. NPM Package Ecosystem
- 3.2.4. Scalability and Performance

### 3.3. DATABASE - MONGODB ....................................... 66
- 3.3.1. NoSQL Database Concepts
- 3.3.2. MongoDB Architecture
- 3.3.3. Mongoose ODM
- 3.3.4. GridFS for File Storage

### 3.4. INTEGRATION TECHNOLOGIES ................................ 74
- 3.4.1. Socket.IO (Real-time Communication)
- 3.4.2. Judge0 CE (Code Execution Engine)
- 3.4.3. Agora RTC (Video Calling)
- 3.4.4. Brevo (Email Service)

### 3.5. TECHNOLOGY COMPARISON AND SELECTION ..................... 81
- 3.5.1. Frontend Alternatives
- 3.5.2. Backend Alternatives
- 3.5.3. Database Alternatives
- 3.5.4. Justification of Technology Stack

---

## CHAPTER 4: SYSTEM DESIGN AND ARCHITECTURE .................... 85

### 4.1. SYSTEM ARCHITECTURE ..................................... 85
- 4.1.1. Overall Architecture
- 4.1.2. Client-Server Model
- 4.1.3. RESTful API Design
- 4.1.4. Real-time Communication Layer

### 4.2. DATABASE DESIGN .......................................... 90
- 4.2.1. Entity Relationship Diagram
- 4.2.2. Collection Schemas (24 collections)
- 4.2.3. Relationships and References
- 4.2.4. Indexing Strategy

### 4.3. USER ROLES AND PERMISSIONS .............................. 95
- 4.3.1. Role-Based Access Control
- 4.3.2. Student Role Capabilities
- 4.3.3. Instructor Role Capabilities
- 4.3.4. Administrator Role Capabilities

### 4.4. USE CASE DIAGRAMS ........................................ 98
- 4.4.1. Student Use Case Diagram
- 4.4.2. Instructor Use Case Diagram
- 4.4.3. Administrator Use Case Diagram
- 4.4.4. Code Assignment Use Case Diagram
- 4.4.5. Video Management Use Case Diagram

### 4.5. DETAILED USE CASE SPECIFICATIONS ....................... 104
- 4.5.1. UC-S01: User Login
- 4.5.2. UC-S03: Submit Assignment
- 4.5.3. UC-S04: Take Quiz
- 4.5.4. UC-S05: Submit Code Assignment
- 4.5.5. UC-I06: Grade Code Submission

### 4.6. SEQUENCE DIAGRAMS ....................................... 115
- 4.6.1. Login Sequence
- 4.6.2. Assignment Submission Sequence
- 4.6.3. Quiz Taking Sequence
- 4.6.4. Code Auto-Grading Sequence

### 4.7. DATABASE SCHEMA DESIGN .................................. 120
- 4.7.1. Core Collections
- 4.7.2. Relationships and Constraints
- 4.7.3. Indexes and Performance Optimization

---

## CHAPTER 5: SYSTEM IMPLEMENTATION ............................. 125

### 5.1. USER INTERFACE IMPLEMENTATION .......................... 125
- 5.1.1. Login Interface
- 5.1.2. Student Interface
- 5.1.3. Instructor Interface
- 5.1.4. Administrator Interface
- 5.1.5. Chat and Notifications

### 5.2. BACKEND SYSTEM IMPLEMENTATION .......................... 150
- 5.2.1. API Documentation
- 5.2.2. Implementation Examples
- 5.2.3. Database Implementation
- 5.2.4. Frontend Services

---

## CHAPTER 6: DEPLOYMENT AND TESTING ........................... 165

### 6.1. INTRODUCTION ............................................ 165

### 6.2. DEPLOYMENT ARCHITECTURE ................................ 166
- 6.2.1. Cloud Infrastructure
- 6.2.2. Deployment Components

### 6.3. PRE-DEPLOYMENT PREPARATION .............................. 168
- 6.3.1. Environment Requirements
- 6.3.2. Environment Variables Setup
- 6.3.3. Pre-deployment Checklist

### 6.4. MONGODB ATLAS SETUP ..................................... 171
- 6.4.1. Database Creation
- 6.4.2. Security Configuration
- 6.4.3. Index Creation
- 6.4.4. Data Seeding

### 6.5. BACKEND DEPLOYMENT (RENDER.COM) ........................ 174
- 6.5.1. Render.com Setup
- 6.5.2. Environment Variables Configuration
- 6.5.3. Deployment Process
- 6.5.4. Custom Domain Setup
- 6.5.5. Health Monitoring
- 6.5.6. Logging and Error Tracking

### 6.6. FRONTEND DEPLOYMENT ..................................... 179
- 6.6.1. Flutter Web Deployment (GitHub Pages)
- 6.6.2. Flutter Mobile Deployment (APK)
- 6.6.3. iOS Deployment (Optional)

### 6.7. EXTERNAL SERVICES CONFIGURATION ........................ 182
- 6.7.1. Judge0 CE Setup
- 6.7.2. Agora RTC Setup
- 6.7.3. Brevo Email Service

### 6.8. DEPLOYMENT TESTING ...................................... 185
- 6.8.1. API Testing with Postman
- 6.8.2. Integration Testing
- 6.8.3. Load Testing
- 6.8.4. Security Testing

### 6.9. MAINTENANCE AND MONITORING .............................. 188
- 6.9.1. Continuous Deployment
- 6.9.2. Backup Strategy
- 6.9.3. Monitoring Dashboard
- 6.9.4. Scaling Strategy

---

## CHAPTER 7: CONCLUSION AND FUTURE WORK ....................... 190

### 7.1. CONCLUSION .............................................. 190
- 7.1.1. Project Overview
- 7.1.2. Achievement Evaluation
- 7.1.3. Project Contributions
- 7.1.4. Testing and Evaluation Results
- 7.1.5. Challenges and Lessons Learned
- 7.1.6. Advantages and Limitations

### 7.2. FUTURE DEVELOPMENT ...................................... 201
- 7.2.1. New Features
- 7.2.2. Technical Improvements
- 7.2.3. Scalability Enhancement
- 7.2.4. Commercialization Plan
- 7.2.5. Community Contributions

### 7.3. FINAL REMARKS ........................................... 210

---

## REFERENCES ................................................... 211

---

## APPENDICES ................................................... 220

### APPENDIX A: IMPORTANT SOURCE CODE .......................... 220
- A.1. Backend - Server Entry Point
- A.2. Frontend - Main Entry Point
- A.3. Authentication Middleware
- A.4. API Service (Flutter)

### APPENDIX B: DATABASE SCHEMAS ................................ 225
- B.1. User Schema
- B.2. Course Schema
- B.3. Assignment Schema
- B.4. Quiz Schema

### APPENDIX C: API REQUEST/RESPONSE EXAMPLES .................. 228
- C.1. User Login
- C.2. Get Courses
- C.3. Submit Assignment
- C.4. Grade Submission

### APPENDIX D: ENVIRONMENT SETUP ............................... 231
- D.1. Backend .env Template
- D.2. Flutter Environment Configuration

### APPENDIX E: DEPLOYMENT COMMANDS ............................. 233
- E.1. Backend Deployment
- E.2. Flutter Web Deployment
- E.3. Flutter Mobile Deployment

### APPENDIX F: TESTING SCRIPTS ................................. 235
- F.1. API Test with curl
- F.2. Load Testing with Artillery

### APPENDIX G: SCREENSHOTS ..................................... 237
- G.1. Authentication Screens
- G.2. Student Screens
- G.3. Instructor Screens
- G.4. Admin Screens

### APPENDIX H: DOCKER CONFIGURATION ............................ 239
- H.1. Backend Dockerfile
- H.2. Docker Compose

### APPENDIX I: ERROR CODES ..................................... 241
- I.1. Backend Error Codes
- I.2. Custom Error Codes

---

**END OF TABLE OF CONTENTS**
