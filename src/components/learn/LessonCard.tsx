"use client";

import Link from "next/link";
import type { Lesson, LessonTier } from "@/lib/types";

const TIER_COLORS: Record<
  LessonTier,
  { bg: string; text: string; border: string; label: string }
> = {
  0: {
    bg: "bg-blue-50",
    text: "text-blue-700",
    border: "border-blue-200",
    label: "Tier 0",
  },
  1: {
    bg: "bg-violet-50",
    text: "text-violet-700",
    border: "border-violet-200",
    label: "Tier 1",
  },
  2: {
    bg: "bg-teal-50",
    text: "text-teal-700",
    border: "border-teal-200",
    label: "Tier 2",
  },
  3: {
    bg: "bg-orange-50",
    text: "text-orange-700",
    border: "border-orange-200",
    label: "Tier 3",
  },
};

export function TierBadge({ tier }: { tier: LessonTier }) {
  const c = TIER_COLORS[tier];

  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${c.bg} ${c.text} ${c.border} whitespace-nowrap`}
    >
      {c.label}
    </span>
  );
}

const CATEGORY_LABELS: Record<string, string> = {
  "bao-lanh": "Bảo lãnh",
  "kinh-nghiem": "Kinh nghiệm",
  "fatal-errors": "Lỗi bị loại",
  deadline: "Deadline",
  "tai-chinh": "Tài chính",
  "ky-thuat": "Kỹ thuật",
  "nhan-su": "Nhân sự",
  "quy-trinh": "Quy trình",
  "hop-dong": "Hợp đồng",
};

interface LessonCardProps {
  lesson: Lesson;
  variant?: "default" | "priority";
}

export function LessonCard({ lesson, variant = "default" }: LessonCardProps) {
  const isPriority = variant === "priority";
  const hasFatalErrors =
    Array.isArray(lesson.fatal_errors) && lesson.fatal_errors.length > 0;
  const categoryLabel = CATEGORY_LABELS[lesson.category] ?? lesson.category;

  return (
    <Link
      href={`/learn/${lesson.slug}`}
      className={`group block rounded-xl border p-4 transition-all duration-150 hover:border-gray-300 hover:shadow-sm ${
        isPriority
          ? "border-amber-200 bg-amber-50/40 hover:bg-amber-50/60"
          : "border-gray-100 bg-white hover:bg-gray-50/50"
      }`}
    >
      <div className="flex items-center justify-between gap-2 mb-2">
        <TierBadge tier={lesson.tier} />
        <div className="flex items-center gap-1.5">
          {hasFatalErrors && (
            <span className="inline-flex items-center gap-1 text-xs text-red-600 bg-red-50 border border-red-200 px-2 py-0.5 rounded">
              <i
                className="ti ti-alert-triangle text-[11px]"
                aria-hidden="true"
              />
              Lỗi chí tử
            </span>
          )}
          {lesson.is_priority && (
            <span className="inline-flex items-center gap-1 text-xs text-amber-700 bg-amber-100 border border-amber-200 px-2 py-0.5 rounded">
              <i className="ti ti-star text-[11px]" aria-hidden="true" />
              Ưu tiên
            </span>
          )}
        </div>
      </div>
      <h3 className="text-sm font-medium text-gray-900 leading-snug group-hover:text-gray-700 mb-1">
        {lesson.title}
      </h3>
      {lesson.objective && (
        <p className="text-xs text-gray-400 leading-relaxed line-clamp-2 mb-3">
          {lesson.objective}
        </p>
      )}
      <div className="flex items-center justify-between">
        <span className="text-xs text-gray-400">{categoryLabel}</span>
        <i
          className="ti ti-arrow-right text-sm text-gray-300 group-hover:text-gray-500 group-hover:translate-x-0.5 transition-transform"
          aria-hidden="true"
        />
      </div>
    </Link>
  );
}
