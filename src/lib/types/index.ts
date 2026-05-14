// ============================================================
// BidMentor — Core TypeScript Types
// ============================================================

// ---- LEARNING ----

export type LessonTier = 0 | 1 | 2 | 3;
export type LessonCategory =
  | "bao-lanh"
  | "kinh-nghiem"
  | "fatal-errors"
  | "deadline"
  | "tai-chinh"
  | "ky-thuat"
  | "nhan-su"
  | "quy-trinh"
  | "hop-dong";

export interface Lesson {
  id: string;
  slug: string;
  title: string;
  title_en?: string;
  tier: LessonTier;
  category: LessonCategory;
  tags: string[];
  objective: string;
  explanation: string;
  content_mdx: string;
  common_mistakes: CommonMistake[];
  fatal_errors: FatalErrorRef[];
  related_slugs: string[];
  quiz?: LessonQuizQuestion[] | null;
  is_published: boolean;
  is_priority: boolean;
  view_count: number;
}

export interface LessonQuizQuestion {
  question: string;
  options: string[];
  correct_answer: string;
  explanation: string;
}

export interface CommonMistake {
  title: string;
  description: string;
  severity: "low" | "medium" | "high" | "fatal";
}

export interface FatalErrorRef {
  description: string;
  law_reference?: string;
}

// ---- GLOSSARY ----

export interface GlossaryTerm {
  id: string;
  slug: string;
  term_vn: string;
  term_en: string;
  short_definition: string; // For tooltip
  full_explanation: string;
  practical_meaning: string;
  risk_note?: string;
  eli5: string;
  law_reference?: string;
  related_term_slugs: string[];
  related_lesson_slugs: string[];
  category: "financial" | "technical" | "legal" | "process" | "compliance";
}

// ---- HSMT ANALYSIS ----

export type RiskLevel = "low" | "medium" | "high" | "fatal";
export type RequirementCategory =
  | "financial"
  | "technical"
  | "personnel"
  | "timeline"
  | "legal"
  | "contract"
  | "process"
  | "compliance";

export interface QuickScanResult {
  recommendation: "GO" | "NO_GO" | "CONDITIONAL_GO";
  confidence_level: "low" | "medium" | "high";
  executive_summary: string;
  ai_reasoning: string;
  fatal_errors: DetectedIssue[];
  high_risks: DetectedRisk[];
  medium_risks: DetectedRisk[];
  critical_requirements: CriticalRequirement[];
  timeline_assessment: string;
  estimated_workload_hours: number;
  learning_suggestions: string[]; // lesson slugs
}

export interface DetectedIssue {
  description: string;
  source_text: string;
  source_location: string;
  law_reference?: string;
}

export interface DetectedRisk extends DetectedIssue {
  category: RequirementCategory;
  mitigation?: string;
}

export interface CriticalRequirement {
  category: RequirementCategory;
  requirement: string;
  source_text: string;
  source_location: string;
  difficulty: "easy" | "medium" | "hard";
  notes?: string;
}

export interface HsmtSession {
  id: string;
  user_id: string;
  project_name: string;
  project_code?: string;
  investor?: string;
  procurement_method?: string;
  estimated_value?: number;
  currency: string;
  file_source?: "google_drive" | "onedrive" | "upload_text" | "manual";
  file_reference_url?: string;
  file_name?: string;
  page_count?: number;
  extracted_text?: string;
  analysis_status: "pending" | "quick_scan_done" | "deep_analysis_done" | "failed";
  submission_deadline?: string;
  validity_period_days?: number;
  tags: string[];
  created_at: string;
  updated_at: string;
}

// ---- COMPARE MODULE ----

export interface CompanyProfile {
  id: string;
  user_id: string;
  company_name: string;
  is_default: boolean;
  annual_revenue_min?: number;
  annual_revenue_max?: number;
  financial_year_reference?: number;
  has_audited_financial: boolean;
  specializations: string[];
  certifications: string[];
  total_staff?: number;
  key_personnel: KeyPersonnel[];
  major_equipment: Equipment[];
  similar_contracts: SimilarContract[];
  available_documents: Record<string, boolean>;
}

export interface KeyPersonnel {
  name: string;
  role: string;
  certifications: string[];
  years_exp: number;
}

export interface Equipment {
  name: string;
  quantity: number;
  owned_or_leased: "owned" | "leased";
}

export interface SimilarContract {
  name: string;
  value: number;
  client: string;
  year: number;
  scope: string;
  has_acceptance: boolean; // Has acceptance certificate (nghiệm thu)
}

export interface GapItem {
  requirement: string;
  company_status: string;
  gap_description: string;
  severity: RiskLevel;
}

export interface CompareResult {
  id: string;
  readiness_score: number; // 0-100
  readiness_level: "not_ready" | "partially_ready" | "ready" | "strong";
  gaps: GapItem[];
  strengths: Array<{ requirement: string; company_status: string; note?: string }>;
  jv_recommended: boolean;
  jv_reasoning?: string;
  suggested_documents: string[];
  ai_reasoning: string;
}

// ---- API RESPONSES ----

export type ApiResponse<T> =
  | { success: true; data: T }
  | { success: false; error: string };

