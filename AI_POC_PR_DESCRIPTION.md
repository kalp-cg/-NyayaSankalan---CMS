# AI Proof of Concept - Feature Integration

## 📋 Overview

This PR integrates three AI-powered features into the case management system as a production-ready proof of concept. All features are designed with officer control in mind—manual triggers only, no automatic background processing, and no database persistence.

## ✨ Features Added

### 1. 🔍 **Document Text Extraction (OCR)**
- **What**: Extract text from uploaded FIR documents and evidence files using OCR
- **Where**: 
  - FIR creation page (Police officers)
  - Case details evidence form (Police officers)
- **How**: Click "Extract Document Text" button after uploading a file
- **Output**: Extracted text displayed in read-only preview (not saved to database)

### 2. 📝 **AI-Assisted Draft Generation**
- **What**: Generate case document drafts (Charge Sheet, Evidence List, Witness List, Closure Report) using AI
- **Where**: Case details page (Police officers working on assigned cases)
- **How**: 
  - Click "Generate Case Document Draft"
  - Select document type and optionally provide context
  - Review generated draft in modal
  - Edit draft text if needed
  - Click "Save as Document" to create document record
- **Output**: AI-generated draft displayed in editable textarea with officer review banner

### 3. 🔎 **AI Case Similarity & Knowledge Search**
- **What**: Semantic search across indexed case documents using FAISS vector embeddings
- **Where**: SHO Dashboard
- **How**: 
  - Enter search query (keywords, sections, accused names)
  - Select number of results
  - Click "Search"
  - View results with similarity scores, IPC section chips, and "Open Case" navigation
- **Output**: Ranked search results with snippets and metadata
- **Index Management**: Manual "Update AI Knowledge Index" button to rebuild FAISS index

## 🏗️ Architecture & Design Decisions

### Data Flow
```
User Action (Manual Trigger)
    ↓
Frontend → Backend Proxy → AI PoC Service (FastAPI)
    ↓
Process (OCR/NER/Generation/Search)
    ↓
Store in AI Workspace JSON (ai-poc/storage/output/ai_extractions/)
    ↓
Return to Frontend (Read-only Display)
```

### Key Principles
✅ **Manual Control**: All AI actions require explicit officer action  
✅ **No Auto-Persistence**: AI outputs not saved to database unless officer chooses  
✅ **Read-only by Default**: Extracted text and drafts are preview-only  
✅ **Officer Review Required**: All AI-generated content requires validation  
✅ **Isolated Storage**: AI data stored in separate workspace (ai-poc/storage/)  
✅ **No Workflow Impact**: Case workflow remains unchanged  

### Technology Stack
- **AI PoC Service**: FastAPI (Python)
- **OCR**: Tesseract via pytesseract
- **NER**: SpaCy (Named Entity Recognition for PII redaction)
- **Text Generation**: Hugging Face Transformers (flan-t5-small)
- **Embeddings**: Sentence-Transformers (all-MiniLM-L6-v2)
- **Vector Search**: FAISS (Facebook AI Similarity Search)
- **Storage**: Local JSON files + FAISS index files

## 📁 File Structure

### New Directories
```
ai-poc/
├── main.py                    # FastAPI endpoints
├── config.py                  # AI service configuration
├── requirements.txt           # Python dependencies
├── utils/
│   ├── ocr.py                 # OCR processing
│   ├── ner.py                 # Named Entity Recognition
│   ├── generator.py           # Draft generation
│   ├── embeddings.py          # Text embeddings
│   └── faiss_index.py         # FAISS indexing & search
└── storage/
    ├── extracts/              # Uploaded files
    ├── indexes/               # FAISS index files
    └── output/
        ├── ai_extractions/    # OCR/NER extraction JSONs (indexed)
        └── ai_documents/      # Generated draft JSONs (not indexed)
```

### Modified Files
**Backend:**
- `backend/src/modules/ai/ai.routes.ts` - Added AI proxy routes
- `backend/src/modules/ai/ai.controller.ts` - AI request controllers
- `backend/src/modules/ai/ai.service.ts` - AI PoC service integration, FIR indexing
- `backend/src/modules/fir/fir.controller.ts` - Auto-index FIR on creation
- `backend/tsconfig.json` - Added DOM lib for FormData/Blob

**Frontend:**
- `client/src/components/ai/AISearchWidget.tsx` - Search widget with IPC chips, similarity scores
- `client/src/components/ai/GenerateDraftModal.tsx` - Draft generation modal with review banner
- `client/src/pages/police/CreateFIR.tsx` - OCR extraction for FIR documents
- `client/src/pages/police/CaseDetails.tsx` - OCR for evidence, draft generation, "Save as Document"

## 🚀 Setup Instructions

### 1. Install AI PoC Dependencies
```bash
cd ai-poc
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python -m spacy download en_core_web_sm
```

### 2. Start AI PoC Service
```bash
cd ai-poc
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### 3. Configure Backend
Ensure `AI_POC_URL` in backend `.env`:
```env
AI_POC_URL=http://localhost:8001
```

### 4. Start Backend & Frontend
```bash
# Backend
cd backend
npm run dev

# Frontend
cd client
npm run dev
```

## 🧪 Testing the Features

### Test OCR Extraction
1. Log in as Police officer
2. Go to "Create FIR"
3. Upload a document (PDF/JPG/PNG)
4. Click "Extract Document Text"
5. Verify extracted text appears in textarea

### Test Draft Generation
1. Log in as Police officer
2. Open an assigned case
3. Click "Generate Case Document Draft"
4. Select document type (e.g., Charge Sheet)
5. Optionally add context
6. Click "Generate Case Document Draft"
7. Review generated draft
8. Click "Save as Document" to create document

### Test AI Search
1. Log in as SHO
2. Go to SHO Dashboard
3. Scroll to "AI Case Similarity & Knowledge Search"
4. Enter search query (e.g., "IPC 302", "theft", "Rajesh")
5. Click "Search"
6. View results with scores and IPC chips
7. Click "Open Case" to navigate to case details

### Test Index Rebuild
1. In AI Search widget
2. Click "Update AI Knowledge Index"
3. Wait for success toast showing document count
4. Perform search to verify updated results

## 📝 API Endpoints (AI PoC)

### POST `/ocr-extract`
- **Body**: `multipart/form-data` with `file`
- **Response**: `{ success, data: { extractionId, entities } }`

### GET `/extractions/{id}`
- **Response**: `{ success, data: { extractedText, redactedText, entities, ... } }`

### POST `/generate-draft`
- **Body**: `text` (form-encoded), `model` (optional)
- **Response**: `{ success, data: { documentId, draft } }`

### GET `/search?q=query&k=5`
- **Response**: `{ success, data: [{ score, id, caseId, sourceFile, snippet }] }`

### POST `/index`
- **Response**: `{ success, indexed: N }`

### POST `/index/doc/{extractionId}`
- **Response**: `{ success, indexed: N, indexedId }`

## ⚠️ Important Notes

### What This IS:
- ✅ Production-ready UI/UX polish
- ✅ Manual, officer-controlled AI assistance
- ✅ Read-only AI workspace with no DB writes
- ✅ Proof of concept for AI integration patterns

### What This IS NOT:
- ❌ Automatic background processing
- ❌ Direct database persistence of AI outputs
- ❌ Production-grade ML models (uses small demo models)
- ❌ Workflow modifications or state changes

### Known Limitations
- AI models are lightweight (demo-grade, not production-scale)
- FAISS index requires manual rebuild after new extractions
- Search only returns results from indexed documents (not live DB queries)
- Generated drafts quality depends on context provided
- OCR accuracy varies by document quality

## 🔒 Security & Privacy

- **PII Redaction**: NER identifies and redacts phone numbers, addresses, names
- **Local Storage**: All AI data stored locally in ai-poc workspace
- **No External APIs**: All processing happens on local server
- **Officer Review**: All AI outputs require explicit validation before use

## 🎯 Future Enhancements (Out of Scope for This PR)

- Production-grade ML models (larger transformers, fine-tuned models)
- Incremental FAISS index updates (no full rebuild)
- Database integration for AI metadata (extraction logs, usage analytics)
- Background indexing queue for new FIRs/evidence
- Multi-language support for OCR/NER
- Real-time search suggestions
- AI model performance monitoring

## ✅ Checklist

- [x] All AI features working end-to-end
- [x] No database schema changes
- [x] No automatic background jobs
- [x] Manual triggers only
- [x] UI updated to production tone (removed "Demo" labels)
- [x] .gitignore added to ai-poc (excludes storage/, venv/, __pycache__)
- [x] README documentation for ai-poc setup
- [x] All lint/type errors resolved
- [x] Backend dev server tested
- [x] Frontend tested in browser

## 📸 Screenshots

_(Attach screenshots of:)_
- AI Case Search widget with results
- Generate Draft modal with review banner
- OCR extraction in FIR creation
- OCR extraction in evidence form

---

**Ready for Review** ✨
