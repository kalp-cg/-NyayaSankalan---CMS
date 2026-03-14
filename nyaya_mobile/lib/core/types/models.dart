// NyayaSankalan - Data Models
// Matches backend API responses exactly

import 'enums.dart';

// ====================================================================
// USER & ORGANIZATION MODELS
// ====================================================================

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final OrganizationType organizationType;
  final String organizationId;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.organizationType,
    required this.organizationId,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: _parseUserRole(json['role']),
      organizationType: _parseOrganizationType(json['organizationType']),
      organizationId: json['organizationId']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.shortName,
      'organizationType': organizationType.name.toUpperCase(),
      'organizationId': organizationId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PoliceStation {
  final String id;
  final String name;
  final String district;
  final String state;

  const PoliceStation({
    required this.id,
    required this.name,
    required this.district,
    required this.state,
  });

  factory PoliceStation.fromJson(Map<String, dynamic> json) {
    return PoliceStation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

class Court {
  final String id;
  final String name;
  final CourtType courtType;
  final String district;
  final String state;

  const Court({
    required this.id,
    required this.name,
    required this.courtType,
    required this.district,
    required this.state,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      courtType: _parseCourtType(json['courtType']),
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

// ====================================================================
// FIR & CASE MODELS
// ====================================================================

class FIR {
  final String id;
  final String firNumber;
  final FirSource firSource;
  final String policeStationId;
  final PoliceStation? policeStation;
  final String registeredBy;
  final User? user;
  final DateTime incidentDate;
  final String sectionsApplied;
  final String firDocumentUrl;
  final DateTime createdAt;
  final Case? case_;

  const FIR({
    required this.id,
    required this.firNumber,
    required this.firSource,
    required this.policeStationId,
    this.policeStation,
    required this.registeredBy,
    this.user,
    required this.incidentDate,
    required this.sectionsApplied,
    required this.firDocumentUrl,
    required this.createdAt,
    this.case_,
  });

  factory FIR.fromJson(Map<String, dynamic> json) {
    return FIR(
      id: json['id']?.toString() ?? '',
      firNumber: json['firNumber']?.toString() ?? '',
      firSource: _parseFirSource(json['firSource']),
      policeStationId: json['policeStationId']?.toString() ?? '',
      policeStation: json['policeStation'] != null
          ? PoliceStation.fromJson(json['policeStation'])
          : null,
      registeredBy: json['registeredBy']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      incidentDate: DateTime.tryParse(json['incidentDate']?.toString() ?? '') ?? DateTime.now(),
      sectionsApplied: json['sectionsApplied']?.toString() ?? '',
      firDocumentUrl: json['firDocumentUrl']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      case_: json['case'] != null ? Case.fromJson(json['case']) : null,
    );
  }
}

class Case {
  final String id;
  final String firId;
  final FIR? fir;
  final DateTime createdAt;
  final bool isArchived;
  final CurrentCaseState? state;
  final List<CaseStateHistory>? stateHistory;
  final List<CaseAssignment>? assignments;
  final List<InvestigationEvent>? investigationEvents;
  final List<Evidence>? evidence;
  final List<Witness>? witnesses;
  final List<Accused>? accused;
  final List<Document>? documents;
  final List<CourtSubmission>? courtSubmissions;
  final List<CourtAction>? courtActions;

  const Case({
    required this.id,
    required this.firId,
    this.fir,
    required this.createdAt,
    required this.isArchived,
    this.state,
    this.stateHistory,
    this.assignments,
    this.investigationEvents,
    this.evidence,
    this.witnesses,
    this.accused,
    this.documents,
    this.courtSubmissions,
    this.courtActions,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id']?.toString() ?? '',
      firId: json['firId']?.toString() ?? '',
      fir: json['fir'] != null ? FIR.fromJson(json['fir']) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isArchived: json['isArchived'] ?? false,
      state: json['state'] != null ? CurrentCaseState.fromJson(json['state']) : null,
      stateHistory: json['stateHistory'] != null
          ? (json['stateHistory'] as List).map((e) => CaseStateHistory.fromJson(e)).toList()
          : null,
      assignments: json['assignments'] != null
          ? (json['assignments'] as List).map((e) => CaseAssignment.fromJson(e)).toList()
          : null,
      investigationEvents: json['investigationEvents'] != null
          ? (json['investigationEvents'] as List).map((e) => InvestigationEvent.fromJson(e)).toList()
          : null,
      evidence: json['evidence'] != null
          ? (json['evidence'] as List).map((e) => Evidence.fromJson(e)).toList()
          : null,
      witnesses: json['witnesses'] != null
          ? (json['witnesses'] as List).map((e) => Witness.fromJson(e)).toList()
          : null,
      accused: json['accused'] != null
          ? (json['accused'] as List).map((e) => Accused.fromJson(e)).toList()
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List).map((e) => Document.fromJson(e)).toList()
          : null,
      courtSubmissions: json['courtSubmissions'] != null
          ? (json['courtSubmissions'] as List).map((e) => CourtSubmission.fromJson(e)).toList()
          : null,
      courtActions: json['courtActions'] != null
          ? (json['courtActions'] as List).map((e) => CourtAction.fromJson(e)).toList()
          : null,
    );
  }
}

class CaseSummary {
  final String id;
  final String caseNumber;
  final String title;
  final String status;
  final DateTime lastUpdated;
  final CaseState? state;
  final String? firNumber;
  final String? sectionsApplied;

  const CaseSummary({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.status,
    required this.lastUpdated,
    this.state,
    this.firNumber,
    this.sectionsApplied,
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) {
    return CaseSummary(
      id: json['id']?.toString() ?? '',
      caseNumber: json['caseNumber']?.toString() ?? 'N/A',
      title: json['title']?.toString() ?? 'Case',
      status: json['status']?.toString() ?? 'UNKNOWN',
      lastUpdated: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      state: json['state'] != null ? _parseCaseState(json['state']) : null,
      firNumber: json['firNumber']?.toString(),
      sectionsApplied: json['sectionsApplied']?.toString(),
    );
  }
}

class CurrentCaseState {
  final String caseId;
  final CaseState currentState;
  final DateTime updatedAt;

  const CurrentCaseState({
    required this.caseId,
    required this.currentState,
    required this.updatedAt,
  });

  factory CurrentCaseState.fromJson(Map<String, dynamic> json) {
    return CurrentCaseState(
      caseId: json['caseId']?.toString() ?? '',
      currentState: _parseCaseState(json['currentState']),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CaseStateHistory {
  final String id;
  final String caseId;
  final CaseState fromState;
  final CaseState toState;
  final String changedBy;
  final User? user;
  final String changeReason;
  final DateTime changedAt;

  const CaseStateHistory({
    required this.id,
    required this.caseId,
    required this.fromState,
    required this.toState,
    required this.changedBy,
    this.user,
    required this.changeReason,
    required this.changedAt,
  });

  factory CaseStateHistory.fromJson(Map<String, dynamic> json) {
    return CaseStateHistory(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      fromState: _parseCaseState(json['fromState']),
      toState: _parseCaseState(json['toState']),
      changedBy: json['changedBy']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      changeReason: json['changeReason']?.toString() ?? '',
      changedAt: DateTime.tryParse(json['changedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CaseAssignment {
  final String id;
  final String caseId;
  final String assignedTo;
  final User? assignedUser;
  final String assignedBy;
  final User? assignerUser;
  final String assignmentReason;
  final DateTime assignedAt;
  final DateTime? unassignedAt;

  const CaseAssignment({
    required this.id,
    required this.caseId,
    required this.assignedTo,
    this.assignedUser,
    required this.assignedBy,
    this.assignerUser,
    required this.assignmentReason,
    required this.assignedAt,
    this.unassignedAt,
  });

  factory CaseAssignment.fromJson(Map<String, dynamic> json) {
    return CaseAssignment(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      assignedTo: json['assignedTo']?.toString() ?? '',
      assignedUser: json['assignedUser'] != null ? User.fromJson(json['assignedUser']) : null,
      assignedBy: json['assignedBy']?.toString() ?? '',
      assignerUser: json['assignerUser'] != null ? User.fromJson(json['assignerUser']) : null,
      assignmentReason: json['assignmentReason']?.toString() ?? '',
      assignedAt: DateTime.tryParse(json['assignedAt']?.toString() ?? '') ?? DateTime.now(),
      unassignedAt: json['unassignedAt'] != null
          ? DateTime.tryParse(json['unassignedAt'].toString())
          : null,
    );
  }
}

// ====================================================================
// INVESTIGATION MODELS
// ====================================================================

class InvestigationEvent {
  final String id;
  final String caseId;
  final InvestigationEventType eventType;
  final String description;
  final String performedBy;
  final User? user;
  final DateTime eventDate;

  const InvestigationEvent({
    required this.id,
    required this.caseId,
    required this.eventType,
    required this.description,
    required this.performedBy,
    this.user,
    required this.eventDate,
  });

  factory InvestigationEvent.fromJson(Map<String, dynamic> json) {
    return InvestigationEvent(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      eventType: _parseInvestigationEventType(json['eventType']),
      description: json['description']?.toString() ?? '',
      performedBy: json['performedBy']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      eventDate: DateTime.tryParse(json['eventDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Evidence {
  final String id;
  final String caseId;
  final EvidenceCategory category;
  final String fileUrl;
  final String? fileName;
  final String? mimeType;
  final String uploadedBy;
  final User? user;
  final DateTime uploadedAt;

  const Evidence({
    required this.id,
    required this.caseId,
    required this.category,
    required this.fileUrl,
    this.fileName,
    this.mimeType,
    required this.uploadedBy,
    this.user,
    required this.uploadedAt,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      category: _parseEvidenceCategory(json['category']),
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      uploadedBy: json['uploadedBy']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Witness {
  final String id;
  final String caseId;
  final String name;
  final String? contact;
  final String? address;
  final String? statementFileUrl;

  const Witness({
    required this.id,
    required this.caseId,
    required this.name,
    this.contact,
    this.address,
    this.statementFileUrl,
  });

  factory Witness.fromJson(Map<String, dynamic> json) {
    return Witness(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contact: json['contact']?.toString(),
      address: json['address']?.toString(),
      statementFileUrl: json['statementFileUrl']?.toString(),
    );
  }
}

class Accused {
  final String id;
  final String caseId;
  final String name;
  final AccusedStatus status;
  final List<BailRecord>? bailRecords;

  const Accused({
    required this.id,
    required this.caseId,
    required this.name,
    required this.status,
    this.bailRecords,
  });

  factory Accused.fromJson(Map<String, dynamic> json) {
    return Accused(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: _parseAccusedStatus(json['status']),
      bailRecords: json['bailRecords'] != null
          ? (json['bailRecords'] as List).map((e) => BailRecord.fromJson(e)).toList()
          : null,
    );
  }
}

// ====================================================================
// DOCUMENT MODELS
// ====================================================================

class Document {
  final String id;
  final String caseId;
  final DocumentType documentType;
  final int version;
  final DocumentStatus status;
  final Map<String, dynamic> contentJson;
  final String createdBy;
  final User? createdByUser;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.caseId,
    required this.documentType,
    required this.version,
    required this.status,
    required this.contentJson,
    required this.createdBy,
    this.createdByUser,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      documentType: _parseDocumentType(json['documentType']),
      version: json['version'] ?? 1,
      status: _parseDocumentStatus(json['status']),
      contentJson: json['contentJson'] ?? {},
      createdBy: json['createdBy']?.toString() ?? '',
      createdByUser: json['createdByUser'] != null ? User.fromJson(json['createdByUser']) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class DocumentRequest {
  final String id;
  final String caseId;
  final String requestedBy;
  final User? requester;
  final String? approvedBy;
  final User? approver;
  final String? issuedBy;
  final User? issuer;
  final DocumentRequestType documentType;
  final DocumentRequestStatus status;
  final String requestReason;
  final String? issuedFileUrl;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentRequest({
    required this.id,
    required this.caseId,
    required this.requestedBy,
    this.requester,
    this.approvedBy,
    this.approver,
    this.issuedBy,
    this.issuer,
    required this.documentType,
    required this.status,
    required this.requestReason,
    this.issuedFileUrl,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentRequest.fromJson(Map<String, dynamic> json) {
    return DocumentRequest(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      requestedBy: json['requestedBy']?.toString() ?? '',
      requester: json['requester'] != null ? User.fromJson(json['requester']) : null,
      approvedBy: json['approvedBy']?.toString(),
      approver: json['approver'] != null ? User.fromJson(json['approver']) : null,
      issuedBy: json['issuedBy']?.toString(),
      issuer: json['issuer'] != null ? User.fromJson(json['issuer']) : null,
      documentType: _parseDocumentRequestType(json['documentType']),
      status: _parseDocumentRequestStatus(json['status']),
      requestReason: json['requestReason']?.toString() ?? '',
      issuedFileUrl: json['issuedFileUrl']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ====================================================================
// COURT MODELS
// ====================================================================

class CourtSubmission {
  final String id;
  final String caseId;
  final int submissionVersion;
  final String submittedBy;
  final User? submittedByUser;
  final DateTime submittedAt;
  final String courtId;
  final Court? court;
  final CourtSubmissionStatus status;
  final Acknowledgement? acknowledgement;

  const CourtSubmission({
    required this.id,
    required this.caseId,
    required this.submissionVersion,
    required this.submittedBy,
    this.submittedByUser,
    required this.submittedAt,
    required this.courtId,
    this.court,
    required this.status,
    this.acknowledgement,
  });

  factory CourtSubmission.fromJson(Map<String, dynamic> json) {
    return CourtSubmission(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      submissionVersion: json['submissionVersion'] ?? 1,
      submittedBy: json['submittedBy']?.toString() ?? '',
      submittedByUser: json['submittedByUser'] != null ? User.fromJson(json['submittedByUser']) : null,
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ?? DateTime.now(),
      courtId: json['courtId']?.toString() ?? '',
      court: json['court'] != null ? Court.fromJson(json['court']) : null,
      status: _parseCourtSubmissionStatus(json['status']),
      acknowledgement: json['acknowledgement'] != null
          ? Acknowledgement.fromJson(json['acknowledgement'])
          : null,
    );
  }
}

class Acknowledgement {
  final String id;
  final String submissionId;
  final String ackNumber;
  final DateTime ackTime;

  const Acknowledgement({
    required this.id,
    required this.submissionId,
    required this.ackNumber,
    required this.ackTime,
  });

  factory Acknowledgement.fromJson(Map<String, dynamic> json) {
    return Acknowledgement(
      id: json['id']?.toString() ?? '',
      submissionId: json['submissionId']?.toString() ?? '',
      ackNumber: json['ackNumber']?.toString() ?? '',
      ackTime: DateTime.tryParse(json['ackTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CourtAction {
  final String id;
  final String caseId;
  final CourtActionType actionType;
  final String? orderFileUrl;
  final DateTime actionDate;

  const CourtAction({
    required this.id,
    required this.caseId,
    required this.actionType,
    this.orderFileUrl,
    required this.actionDate,
  });

  factory CourtAction.fromJson(Map<String, dynamic> json) {
    return CourtAction(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      actionType: _parseCourtActionType(json['actionType']),
      orderFileUrl: json['orderFileUrl']?.toString(),
      actionDate: DateTime.tryParse(json['actionDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BailRecord {
  final String id;
  final String caseId;
  final String accusedId;
  final BailType bailType;
  final BailStatus status;
  final String orderDocumentUrl;
  final DateTime createdAt;

  const BailRecord({
    required this.id,
    required this.caseId,
    required this.accusedId,
    required this.bailType,
    required this.status,
    required this.orderDocumentUrl,
    required this.createdAt,
  });

  factory BailRecord.fromJson(Map<String, dynamic> json) {
    return BailRecord(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      accusedId: json['accusedId']?.toString() ?? '',
      bailType: _parseBailType(json['bailType']),
      status: _parseBailStatus(json['status']),
      orderDocumentUrl: json['orderDocumentUrl']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ====================================================================
// NOTIFICATION MODEL
// ====================================================================

class Notification {
  final String id;
  final String title;
  final String message;
  final String relatedCaseId;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.relatedCaseId,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      relatedCaseId: json['relatedCaseId']?.toString() ?? '',
      type: _parseNotificationType(json['type']),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ====================================================================
// HELPER FUNCTIONS
// ====================================================================

UserRole _parseUserRole(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return UserRole.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => UserRole.police,
  );
}

OrganizationType _parseOrganizationType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return OrganizationType.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => OrganizationType.policeStation,
  );
}

CourtType _parseCourtType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return CourtType.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => CourtType.magistrate,
  );
}

FirSource _parseFirSource(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return FirSource.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => FirSource.police,
  );
}

CaseState _parseCaseState(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return CaseState.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => CaseState.firRegistered,
  );
}

AccusedStatus _parseAccusedStatus(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return AccusedStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => AccusedStatus.arrested,
  );
}

EvidenceCategory _parseEvidenceCategory(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return EvidenceCategory.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => EvidenceCategory.photo,
  );
}

DocumentType _parseDocumentType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return DocumentType.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => DocumentType.chargeSheet,
  );
}

DocumentStatus _parseDocumentStatus(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return DocumentStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => DocumentStatus.draft,
  );
}

DocumentRequestType _parseDocumentRequestType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return DocumentRequestType.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => DocumentRequestType.other,
  );
}

DocumentRequestStatus _parseDocumentRequestStatus(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return DocumentRequestStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => DocumentRequestStatus.requested,
  );
}

InvestigationEventType _parseInvestigationEventType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return InvestigationEventType.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => InvestigationEventType.other,
  );
}

BailType _parseBailType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return BailType.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => BailType.police,
  );
}

BailStatus _parseBailStatus(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return BailStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => BailStatus.applied,
  );
}

CourtSubmissionStatus _parseCourtSubmissionStatus(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return CourtSubmissionStatus.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => CourtSubmissionStatus.submitted,
  );
}

CourtActionType _parseCourtActionType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return CourtActionType.values.firstWhere(
    (e) => e.name.toLowerCase() == str || e.name.toLowerCase().replaceAll('_', '') == str,
    orElse: () => CourtActionType.hearing,
  );
}

NotificationType _parseNotificationType(dynamic value) {
  final str = value?.toString().toLowerCase() ?? '';
  return NotificationType.values.firstWhere(
    (e) => e.name.toLowerCase() == str,
    orElse: () => NotificationType.info,
  );
}
