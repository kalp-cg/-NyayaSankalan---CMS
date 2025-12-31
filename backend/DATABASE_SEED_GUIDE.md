# Database Seed Guide

## Quick Start

To populate your database with realistic dummy data:

```bash
cd backend
npm run db:seed
```

## What Gets Seeded

### Organizations
- **2 Police Stations**
  - Central Police Station (Central District, Karnataka)
  - North Police Station (North District, Karnataka)

- **2 Courts**
  - District Court - Central (Magistrate)
  - High Court - State (High Court)

### Users (6 Total)
All passwords: `password123`

| Role | Email | Name | Organization |
|------|-------|------|--------------|
| SHO | sho.central@police.gov | Rajesh Kumar | Central Police Station |
| Police | officer1@police.gov | Priya Sharma | Central Police Station |
| Police | officer2@police.gov | Amit Patel | Central Police Station |
| SHO | sho.north@police.gov | Suresh Reddy | North Police Station |
| Court Clerk | clerk@court.gov | Anita Desai | District Court |
| Judge | judge@court.gov | Justice M. S. Singh | District Court |

### Cases & Data

#### **Case 1: FIR/2025/0001** (Murder Case)
- **Status:** UNDER_INVESTIGATION
- **Sections:** IPC 302, 201
- **Incident Date:** Jan 15, 2025
- **Investigating Officer:** Priya Sharma
- **Accused:** 
  - Ravi Varma (Arrested)
  - Mohan Lal (Absconding)
- **Investigation Events:**
  - Search at suspect residence
  - Seizure of murder weapon
  - Eyewitness statement recorded
- **Evidence:** Crime scene photos, Forensic report
- **Witnesses:** 2 (Ramesh Kumar, Lakshmi Devi)
- **Document Requests:**
  - Arrest Warrant (ISSUED)
  - Search Warrant (SHO_APPROVED)
- **Document Checklist:** 4 items (3 uploaded)

#### **Case 2: FIR/2025/0002** (Theft Case)
- **Status:** CHARGE_SHEET_PREPARED
- **Sections:** IPC 379, 411
- **Incident Date:** Feb 10, 2025
- **Investigating Officer:** Amit Patel
- **Accused:** Sunil Choudhary (ON_BAIL)
- **Investigation Events:**
  - Search at pawn shop
  - Recovery of stolen jewelry (Rs. 2.5 lakhs)
- **Evidence:** Photos of stolen items
- **Witnesses:** 1 (Vijay Singh)
- **Documents:** Charge Sheet (FINAL)
- **Bail:** Court bail granted
- **Court Submission:** Submitted to District Court (with acknowledgment)
- **Court Actions:** Cognizance taken
- **Document Checklist:** 2 items (both uploaded)

#### **Case 3: FIR/2025/0003** (Fraud Case - Closed)
- **Status:** CLOSURE_REPORT_PREPARED
- **Sections:** IPC 420, 120B
- **Incident Date:** Mar 5, 2025
- **Source:** Court Order
- **Investigating Officer:** Suresh Reddy (SHO)
- **Documents:** Closure Report (FINAL)
- **Closure Reason:** Insufficient evidence
- **Case Reopen Request:** 
  - Status: APPROVED by Judge
  - Reason: New evidence discovered
  - Decided: Apr 18, 2025

### Additional Data
- **Case State History:** 6 state transitions tracked
- **Case Assignments:** 3 assignments made
- **Audit Logs:** 3 sample entries

## Reset Database

To reset and reseed from scratch:

```bash
cd backend
npx prisma migrate reset
# This will:
# 1. Drop the database
# 2. Create it again
# 3. Run all migrations
# 4. Run the seed automatically
```

## Verify Seeded Data

View data in Prisma Studio:
```bash
npm run db:studio
```

## Testing Scenarios

### As Police Officer (Priya Sharma)
- Login: `officer1@police.gov` / `password123`
- View Case 1 under investigation
- Add investigation events
- Upload evidence
- Request warrants

### As SHO (Rajesh Kumar)
- Login: `sho.central@police.gov` / `password123`
- Approve document requests
- Assign cases to officers
- Change case states
- Prepare charge sheets

### As Court Clerk (Anita Desai)
- Login: `clerk@court.gov` / `password123`
- View submitted cases
- Issue warrants
- Create acknowledgments

### As Judge (Justice M. S. Singh)
- Login: `judge@court.gov` / `password123`
- Review case reopen requests
- Approve/reject requests
- View court submissions

## Data Summary

✅ **3 FIRs** covering different crime types (Murder, Theft, Fraud)  
✅ **3 Cases** in different states (Investigation, Charge Sheet, Closure)  
✅ **3 Accused** with different statuses (Arrested, On Bail, Absconding)  
✅ **5 Investigation Events** across cases  
✅ **3 Evidence Items** (Photos, Forensic reports)  
✅ **3 Witnesses** with contact details  
✅ **2 Legal Documents** (Charge Sheet, Closure Report)  
✅ **1 Bail Record** (Granted)  
✅ **1 Court Submission** with acknowledgment  
✅ **2 Document Requests** (Arrest & Search Warrants)  
✅ **1 Court Action** (Cognizance)  
✅ **1 Case Reopen Request** (Approved)  
✅ **6 Document Checklist Items**  
✅ **3 Audit Log Entries**

## Notes

- All users have the same password for testing: `password123`
- Dates are realistic and sequential (Jan-Apr 2025)
- URLs point to example.com (replace with actual Cloudinary URLs in production)
- Case progression follows realistic workflow
- Different case states demonstrate various stages of investigation
