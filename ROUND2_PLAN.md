# Round 2 Plan - NyayaSankalan

> Planned improvements for Round 2 focusing on scalability, security, compliance, and production readiness

---

## Executive Summary

This document outlines **4 major improvements** planned for Round 2 of the hackathon. Each improvement addresses real-world deployment requirements and demonstrates the path from prototype to production-ready system.

---

## Improvement 1: Real-Time Notifications & WebSocket Integration

### Current State (Round 1)
- Users must manually refresh to see updates
- No push notifications for case state changes
- Polling-based approach (inefficient)

### Planned Enhancement

**Objective:** Implement real-time notifications using WebSocket for instant updates across users.

### Technical Implementation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NOTIFICATION ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐         ┌──────────────┐         ┌──────────────┐           │
│   │  Client  │◀────────│  Socket.io   │◀────────│  Redis Pub/  │           │
│   │  React   │ WebSocket│  Server      │         │  Sub         │           │
│   └──────────┘         └──────────────┘         └──────────────┘           │
│                                                        ▲                    │
│                                                        │                    │
│                                                        │ Publish            │
│                                                        │                    │
│                                               ┌────────┴───────┐            │
│                                               │  Event Emitter │            │
│                                               │  (on state     │            │
│                                               │   change)      │            │
│                                               └────────────────┘            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Notification Types

| Event | Recipients | Priority |
|-------|------------|----------|
| Case Assigned | Assigned Officer | High |
| Case State Changed | All stakeholders | Medium |
| Document Request Created | SHO | High |
| Court Submission Accepted | SHO + Police | High |
| Court Submission Returned | SHO + Police | High |
| Judgment Delivered | All parties | Critical |
| Deadline Approaching | Assigned Officer | High |
| Case Reopened | Original Investigator | Medium |

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| WebSocket Server | Socket.io | Real-time bidirectional communication |
| Message Broker | Redis Pub/Sub | Cross-instance message distribution |
| Notification Store | PostgreSQL | Persistent notification history |
| Push Notifications | Firebase Cloud Messaging | Mobile/browser push (future) |

### Implementation Steps

1. Add Socket.io to Express server
2. Create notification service with event types
3. Integrate Redis for horizontal scaling
4. Update frontend with Socket.io client
5. Add notification center UI component
6. Store notification history in database

### Expected Impact

| Metric | Before | After |
|--------|--------|-------|
| Update latency | 30-60s (polling) | <1s (real-time) |
| Server requests | High (polling) | Low (push) |
| User experience | Manual refresh | Instant updates |
| Deadline awareness | Low | High |

---

## Improvement 2: Comprehensive Deadline Management

### Current State (Round 1)
- Basic deadline schema exists but not fully implemented
- No automated deadline calculation
- No alerts for approaching/missed deadlines

### Planned Enhancement

**Objective:** Implement automated deadline tracking with alerts based on CrPC timelines.

### Legal Deadlines (CrPC Compliance)

| Stage | Deadline | CrPC Reference |
|-------|----------|----------------|
| Charge sheet filing | 60/90 days from arrest | Section 167 |
| Police custody remand | 15 days max | Section 167(2) |
| Judicial custody | 60/90 days | Section 167(2) |
| Bail hearing response | 48 hours | Section 57 |
| Trial commencement | Within stipulated time | State guidelines |

### Technical Implementation

```typescript
// Deadline calculation service
interface DeadlineConfig {
  stage: CaseState;
  daysFromTrigger: number;
  triggerEvent: string;
  crpcReference: string;
  alertDaysBefore: number[];
}

const DEADLINE_RULES: DeadlineConfig[] = [
  {
    stage: 'UNDER_INVESTIGATION',
    daysFromTrigger: 60,
    triggerEvent: 'FIRST_ACCUSED_ARRESTED',
    crpcReference: 'Section 167',
    alertDaysBefore: [30, 15, 7, 3, 1],
  },
  // ... more rules
];
```

### Deadline Dashboard

| Column | Description |
|--------|-------------|
| Case ID | Case identifier |
| Deadline Type | Charge sheet, remand, etc. |
| Due Date | Calculated deadline |
| Days Remaining | Auto-calculated |
| Status | On Track / At Risk / Overdue |
| Actions | Extend (with reason) / Mark Complete |

### Alert System Integration

```
Deadline - 30 days: Email notification
Deadline - 15 days: In-app notification
Deadline - 7 days: Daily reminders + SHO notification
Deadline - 3 days: Critical alert + escalation
Deadline - 1 day: Urgent alert to SHO + Court
Deadline passed: Automatic escalation + audit log
```

### Expected Impact

| Metric | Before | After |
|--------|--------|-------|
| Deadline compliance | Manual tracking | Automated |
| Missed deadlines | Untracked | Zero tolerance |
| CrPC compliance | Partial | Full |
| Officer awareness | Low | High |

---

## Improvement 3: Enhanced Security & Audit Compliance

### Current State (Round 1)
- Basic JWT authentication
- Role-based access control
- Simple audit logging

### Planned Enhancement

**Objective:** Implement enterprise-grade security with comprehensive audit compliance.

### Security Enhancements

#### 3.1 Multi-Factor Authentication (MFA)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MFA AUTHENTICATION FLOW                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │ Username │───▶│ Password │───▶│   OTP    │───▶│  Access  │             │
│   │ Entry    │    │ Verify   │    │  Verify  │    │ Granted  │             │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘             │
│                                         │                                   │
│                                         ▼                                   │
│                                  ┌─────────────┐                            │
│                                  │ TOTP / SMS  │                            │
│                                  │ Verification│                            │
│                                  └─────────────┘                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Implementation:**
- TOTP-based (Google Authenticator, Microsoft Authenticator)
- SMS fallback for critical actions
- Mandatory for Judge role
- Optional for other roles (configurable by admin)

#### 3.2 Session Management

| Feature | Implementation |
|---------|----------------|
| Session timeout | 30 minutes inactivity |
| Concurrent sessions | Max 2 per user |
| Session revocation | Admin can force logout |
| Device tracking | Log device/browser info |
| Geo-location | Flag unusual locations |

#### 3.3 Enhanced Audit Logging

| Field | Current | Enhanced |
|-------|---------|----------|
| User ID | ✅ | ✅ |
| Action | ✅ | ✅ |
| Timestamp | ✅ | ✅ |
| IP Address | ❌ | ✅ |
| User Agent | ❌ | ✅ |
| Geo Location | ❌ | ✅ |
| Session ID | ❌ | ✅ |
| Request Body | ❌ | ✅ (sensitive fields masked) |
| Response Status | ❌ | ✅ |
| Execution Time | ❌ | ✅ |

#### 3.4 Data Encryption

| Data Type | Current | Enhanced |
|-----------|---------|----------|
| Passwords | bcrypt | bcrypt (unchanged) |
| JWT tokens | HS256 | RS256 (asymmetric) |
| PII fields | Plaintext | AES-256 encryption |
| Files at rest | Cloudinary default | Client-side encryption |
| Database | Plaintext | Column-level encryption |

#### 3.5 API Security

| Feature | Implementation |
|---------|----------------|
| Rate limiting | 100 req/min per user |
| Request signing | HMAC signature validation |
| Input sanitization | Enhanced XSS prevention |
| SQL injection | Already covered by Prisma |
| CSRF protection | Token-based validation |

### Compliance Features

| Standard | Feature |
|----------|---------|
| **IT Act 2000** | Secure access logging |
| **Evidence Act** | Chain of custody tracking |
| **RTI Act** | Data export capabilities |
| **DPDP Act 2023** | PII handling, consent management |

### Expected Impact

| Metric | Before | After |
|--------|--------|-------|
| Authentication strength | Password only | MFA enabled |
| Audit completeness | Basic | Comprehensive |
| Data protection | Minimal | End-to-end |
| Compliance readiness | Partial | Full |

---

## Improvement 4: AI Enhancement & Model Upgrade

### Current State (Round 1)
- Basic OCR with pytesseract
- Simple NER with spaCy (en_core_web_sm)
- Text generation with FLAN-T5 small
- Local FAISS index

### Planned Enhancement

**Objective:** Upgrade AI capabilities for better accuracy and legal domain specialization.

### 4.1 Legal Domain NER Model

**Current Limitations:**
- Generic English NER model
- Poor recognition of legal entities
- No understanding of Indian legal terminology

**Enhancement:**

| Entity Type | Current Detection | Enhanced Detection |
|-------------|-------------------|-------------------|
| IPC Sections | Regex only | Fine-tuned NER |
| BNS Sections | ❌ | ✅ (new criminal code) |
| Case Citations | ❌ | ✅ (AIR, SCC, etc.) |
| Court Names | Generic ORG | Specific court NER |
| Judge Names | Generic PERSON | Specialized detection |
| Legal Terms | ❌ | ✅ (bail, remand, etc.) |

**Training Approach:**
- Fine-tune spaCy model on Indian legal corpus
- Add custom entity types for legal domain
- Use labeled data from public court judgments

### 4.2 Multilingual OCR Support

| Language | Current | Enhanced |
|----------|---------|----------|
| English | ✅ | ✅ |
| Hindi (Devanagari) | ❌ | ✅ |
| Regional languages | ❌ | ✅ (configurable) |

**Implementation:**
- Integrate Tesseract language packs
- Add language detection
- Support mixed-language documents (common in FIRs)

### 4.3 Advanced Document Generation

**Current:** Basic charge sheet draft from facts

**Enhanced:**
| Feature | Description |
|---------|-------------|
| Template Library | Multiple document templates |
| Section Suggestion | Recommend IPC sections based on facts |
| Precedent Matching | Find similar cases from index |
| Legal Language | Generate legally accurate phrasing |
| Multi-format Output | PDF, DOCX, editable formats |

### 4.4 Improved Semantic Search

**Current:** Basic FAISS with sentence-transformers

**Enhanced:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ENHANCED SEARCH ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Query ──▶ [Query Expansion] ──▶ [Embedding] ──▶ [FAISS Search]            │
│                    │                                     │                  │
│                    ▼                                     ▼                  │
│            Legal synonyms                         Candidate results         │
│            added                                         │                  │
│                                                          ▼                  │
│                                                  [Re-ranking Model]         │
│                                                          │                  │
│                                                          ▼                  │
│                                                   Final results             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

| Feature | Current | Enhanced |
|---------|---------|----------|
| Embedding model | all-MiniLM-L6-v2 | Legal domain fine-tuned |
| Query expansion | ❌ | Legal synonym expansion |
| Re-ranking | ❌ | Cross-encoder re-ranking |
| Filters | Basic | IPC section, date range, court |
| Faceted search | ❌ | By case type, status, court |

### 4.5 Model Deployment

| Aspect | Current | Enhanced |
|--------|---------|----------|
| Hosting | Local | Cloud GPU (optional) |
| Caching | None | Model prediction caching |
| Batching | None | Batch processing for bulk |
| Monitoring | None | Prediction quality metrics |

### Expected Impact

| Metric | Before | After |
|--------|--------|-------|
| NER accuracy (legal entities) | ~60% | ~90% |
| OCR language support | 1 | 5+ |
| Search relevance | Basic | High |
| Document generation quality | Template-based | Context-aware |

---

## Implementation Timeline

| Week | Improvement | Key Deliverables |
|------|-------------|------------------|
| Week 1 | Real-time Notifications | Socket.io integration, notification service |
| Week 2 | Real-time Notifications | Redis pub/sub, frontend components |
| Week 3 | Deadline Management | Deadline calculation engine, alerts |
| Week 4 | Deadline Management | Dashboard UI, escalation workflow |
| Week 5 | Security Enhancement | MFA implementation, session management |
| Week 6 | Security Enhancement | Enhanced audit, encryption |
| Week 7 | AI Enhancement | Legal NER model training |
| Week 8 | AI Enhancement | Multilingual OCR, search improvements |

---

## Resource Requirements

### Infrastructure

| Resource | Current | Round 2 |
|----------|---------|---------|
| Application Server | 1 instance | 2 instances (HA) |
| Database | Single PostgreSQL | PostgreSQL + Redis |
| File Storage | Cloudinary | Cloudinary (unchanged) |
| AI Compute | CPU only | GPU instance (optional) |

### External Services

| Service | Purpose | Cost Estimate |
|---------|---------|---------------|
| Redis Cloud | Pub/sub, caching | Free tier available |
| Twilio/MSG91 | SMS for MFA | Pay-per-use |
| GPU Cloud | AI model inference | On-demand |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Notification delivery latency | <1 second |
| Deadline compliance rate | >95% |
| MFA adoption | 100% for judges |
| NER accuracy | >90% |
| Search relevance (user feedback) | 4+/5 rating |
| Security audit score | A rating |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| WebSocket scalability | Redis pub/sub for horizontal scaling |
| MFA user friction | SMS fallback, remember device option |
| AI model accuracy | Human review workflow before final submission |
| Infrastructure cost | Start with free tiers, scale as needed |

---

## Conclusion

These Round 2 improvements transform NyayaSankalan from a functional prototype to a production-ready system that:

1. **Improves User Experience** - Real-time updates, deadline awareness
2. **Ensures Compliance** - CrPC deadlines, audit trails
3. **Strengthens Security** - MFA, encryption, comprehensive logging
4. **Enhances AI Capabilities** - Legal domain specialization, multilingual support

Each improvement is realistic, implementable within the hackathon timeline, and directly addresses feedback areas for production deployment.
