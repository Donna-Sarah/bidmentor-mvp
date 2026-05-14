import Link from "next/link";
import { LessonCard, TierBadge } from "@/components/learn/LessonCard";
import { getLessonsGroupedByTier } from "@/lib/supabase/queries/lessons";
import type { Lesson, LessonTier } from "@/lib/types";

const TIER_META: Record<LessonTier, { label: string; description: string }> = {
  0: {
    label: "Định hướng",
    description: "Bức tranh lớn - đấu thầu là gì, quy trình thế nào",
  },
  1: {
    label: "Nền tảng",
    description: "Điều kiện, bảo lãnh, chấm điểm, lỗi bị loại",
  },
  2: {
    label: "Thực chiến",
    description: "Quick Scan, GAP analysis, checklist, hồ sơ",
  },
  3: {
    label: "Nâng cao",
    description: "Liên danh, chiến lược giá, SOP, knowledge",
  },
};

export default async function LearnPage() {
  const lessonsByTier = await getLessonsGroupedByTier();
  const totalLessons = Object.values(lessonsByTier).reduce(
    (sum, arr) => sum + arr.length,
    0,
  );
  const priorityLessons = Object.values(lessonsByTier)
    .flat()
    .filter((l) => l.is_priority)
    .slice(0, 4);

  return (
    <div className="max-w-4xl mx-auto px-4 py-10 space-y-12">
      <div className="space-y-2">
        <h1 className="text-2xl font-medium text-gray-900">
          Học đấu thầu thực chiến
        </h1>
        <p className="text-gray-500 text-base leading-relaxed">
          {totalLessons} bài học thực tế - không lý thuyết, không học thuộc
          lòng.
          <br />
          Học đúng thứ bạn cần để đọc HSMT và tránh bị loại.
        </p>
      </div>

      {priorityLessons.length > 0 && (
        <section className="space-y-4">
          <span className="text-sm font-medium text-amber-700 bg-amber-50 border border-amber-200 px-3 py-1 rounded-full">
            Bắt đầu từ đây
          </span>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {priorityLessons.map((lesson) => (
              <LessonCard key={lesson.id} lesson={lesson} variant="priority" />
            ))}
          </div>
        </section>
      )}

      {(Object.entries(lessonsByTier) as [string, Lesson[]][]).map(
        ([tierStr, lessons]) => {
          const tier = Number(tierStr) as LessonTier;
          const meta = TIER_META[tier];
          if (!lessons.length) return null;

          return (
            <section key={tier} className="space-y-4">
              <div className="flex items-start gap-3 pb-3 border-b border-gray-100">
                <TierBadge tier={tier} />
                <div>
                  <h2 className="text-base font-medium text-gray-900">
                    {meta.label}
                  </h2>
                  <p className="text-sm text-gray-400 mt-0.5">
                    {meta.description}
                  </p>
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {lessons.map((lesson) => (
                  <LessonCard key={lesson.id} lesson={lesson} />
                ))}
              </div>
            </section>
          );
        },
      )}

      <div className="pt-4 border-t border-gray-100">
        <Link
          href="/glossary"
          className="inline-flex items-center gap-2 text-sm text-gray-500 hover:text-gray-800 transition-colors"
        >
          <i className="ti ti-book-2" aria-hidden="true" />
          Xem Glossary - tra cứu thuật ngữ đấu thầu
          <i className="ti ti-arrow-right text-xs" aria-hidden="true" />
        </Link>
      </div>
    </div>
  );
}
