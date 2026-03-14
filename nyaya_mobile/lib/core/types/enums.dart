// NyayaSankalan - Core Enums
// Matches backend Prisma schema exactly

enum UserRole {
  police,
  sho,
  courtClerk,
  judge,
}

enum OrganizationType {
  policeStation,
  court,
}

enum CourtType {
  magistrate,
  sessions,
  highCourt,
}

enum FirSource {
  police,
  courtOrder,
}

enum CaseState {
  firRegistered,
  caseAssigned,
  underInvestigation,
  investigationPaused,
  investigationCompleted,
  chargeSheetPrepared,
  closureReportPrepared,
  submittedToCourt,
  returnedForDefects,
  resubmittedToCourt,
  courtAccepted,
  trialOngoing,
  judgmentReserved,
  disposed,
  appealed,
  archived,
}

enum AccusedStatus {
  arrested,
  onBail,
  absconding,
}

enum EvidenceCategory {
  photo,
  report,
  forensic,
  statement,
}

enum DocumentType {
  chargeSheet,
  evidenceList,
  witnessList,
  closureReport,
  remandApplication,
}

enum DocumentStatus {
  draft,
  final_,
  locked,
}

enum DocumentRequestType {
  arrestWarrant,
  searchWarrant,
  remandOrder,
  chargeSheetCopy,
  other,
}

enum DocumentRequestStatus {
  requested,
  shoApproved,
  issued,
  rejected,
}

enum CaseReopenStatus {
  requested,
  approved,
  rejected,
}

enum BailType {
  police,
  anticipatory,
  court,
}

enum BailStatus {
  applied,
  granted,
  rejected,
}

enum CourtSubmissionStatus {
  submitted,
  underReview,
  accepted,
  returned,
}

enum CourtActionType {
  cognizance,
  chargesFramed,
  hearing,
  judgment,
  sentence,
  acquittal,
  conviction,
}

enum InvestigationEventType {
  search,
  seizure,
  statement,
  transfer,
  other,
}

enum NotificationType {
  info,
  action,
  warning,
}

// Extension methods for enums
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.police:
        return 'Police Officer';
      case UserRole.sho:
        return 'Station House Officer';
      case UserRole.courtClerk:
        return 'Court Clerk';
      case UserRole.judge:
        return 'Judge';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.police:
        return 'POLICE';
      case UserRole.sho:
        return 'SHO';
      case UserRole.courtClerk:
        return 'COURT_CLERK';
      case UserRole.judge:
        return 'JUDGE';
    }
  }
}

extension CaseStateExtension on CaseState {
  String get displayName {
    switch (this) {
      case CaseState.firRegistered:
        return 'FIR Registered';
      case CaseState.caseAssigned:
        return 'Case Assigned';
      case CaseState.underInvestigation:
        return 'Under Investigation';
      case CaseState.investigationPaused:
        return 'Investigation Paused';
      case CaseState.investigationCompleted:
        return 'Investigation Completed';
      case CaseState.chargeSheetPrepared:
        return 'Charge Sheet Prepared';
      case CaseState.closureReportPrepared:
        return 'Closure Report Prepared';
      case CaseState.submittedToCourt:
        return 'Submitted to Court';
      case CaseState.returnedForDefects:
        return 'Returned for Defects';
      case CaseState.resubmittedToCourt:
        return 'Resubmitted to Court';
      case CaseState.courtAccepted:
        return 'Court Accepted';
      case CaseState.trialOngoing:
        return 'Trial Ongoing';
      case CaseState.judgmentReserved:
        return 'Judgment Reserved';
      case CaseState.disposed:
        return 'Disposed';
      case CaseState.appealed:
        return 'Appealed';
      case CaseState.archived:
        return 'Archived';
    }
  }

  String get backendValue {
    return name.toUpperCase();
  }

  bool get isPolicePhase {
    return [
      CaseState.firRegistered,
      CaseState.caseAssigned,
      CaseState.underInvestigation,
      CaseState.investigationPaused,
      CaseState.investigationCompleted,
      CaseState.chargeSheetPrepared,
      CaseState.closureReportPrepared,
      CaseState.submittedToCourt,
      CaseState.returnedForDefects,
      CaseState.resubmittedToCourt,
    ].contains(this);
  }

  bool get isCourtPhase {
    return [
      CaseState.courtAccepted,
      CaseState.trialOngoing,
      CaseState.judgmentReserved,
      CaseState.disposed,
      CaseState.appealed,
      CaseState.archived,
    ].contains(this);
  }
}

extension EvidenceCategoryExtension on EvidenceCategory {
  String get displayName {
    switch (this) {
      case EvidenceCategory.photo:
        return 'Photograph';
      case EvidenceCategory.report:
        return 'Report';
      case EvidenceCategory.forensic:
        return 'Forensic';
      case EvidenceCategory.statement:
        return 'Statement';
    }
  }
}

extension AccusedStatusExtension on AccusedStatus {
  String get displayName {
    switch (this) {
      case AccusedStatus.arrested:
        return 'Arrested';
      case AccusedStatus.onBail:
        return 'On Bail';
      case AccusedStatus.absconding:
        return 'Absconding';
    }
  }
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.chargeSheet:
        return 'Charge Sheet';
      case DocumentType.evidenceList:
        return 'Evidence List';
      case DocumentType.witnessList:
        return 'Witness List';
      case DocumentType.closureReport:
        return 'Closure Report';
      case DocumentType.remandApplication:
        return 'Remand Application';
    }
  }
}

extension BailStatusExtension on BailStatus {
  String get displayName {
    switch (this) {
      case BailStatus.applied:
        return 'Applied';
      case BailStatus.granted:
        return 'Granted';
      case BailStatus.rejected:
        return 'Rejected';
    }
  }
}

extension CourtActionTypeExtension on CourtActionType {
  String get displayName {
    switch (this) {
      case CourtActionType.cognizance:
        return 'Cognizance';
      case CourtActionType.chargesFramed:
        return 'Charges Framed';
      case CourtActionType.hearing:
        return 'Hearing';
      case CourtActionType.judgment:
        return 'Judgment';
      case CourtActionType.sentence:
        return 'Sentence';
      case CourtActionType.acquittal:
        return 'Acquittal';
      case CourtActionType.conviction:
        return 'Conviction';
    }
  }
}
