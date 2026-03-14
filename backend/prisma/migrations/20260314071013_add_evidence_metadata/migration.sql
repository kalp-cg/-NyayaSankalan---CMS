/*
  Warnings:

  - You are about to drop the `case_briefs` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `case_readiness_checks` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `document_validations` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "case_briefs" DROP CONSTRAINT "case_briefs_caseId_fkey";

-- DropForeignKey
ALTER TABLE "case_briefs" DROP CONSTRAINT "case_briefs_generatedBy_fkey";

-- DropForeignKey
ALTER TABLE "case_readiness_checks" DROP CONSTRAINT "case_readiness_checks_caseId_fkey";

-- DropForeignKey
ALTER TABLE "case_readiness_checks" DROP CONSTRAINT "case_readiness_checks_checkedBy_fkey";

-- DropForeignKey
ALTER TABLE "document_validations" DROP CONSTRAINT "document_validations_caseId_fkey";

-- DropForeignKey
ALTER TABLE "document_validations" DROP CONSTRAINT "document_validations_validatedBy_fkey";

-- AlterTable
ALTER TABLE "evidence" ADD COLUMN     "fileName" TEXT,
ADD COLUMN     "mimeType" TEXT;

-- DropTable
DROP TABLE "case_briefs";

-- DropTable
DROP TABLE "case_readiness_checks";

-- DropTable
DROP TABLE "document_validations";
