import Link from "next/link";
import { notFound } from "next/navigation";
import { ActionNextStep } from "@/components/ActionNextStep";
import { CaseFail } from "@/components/CaseFail";
import { LessonBody } from "@/components/learn/LessonBody";
import { LessonCard, TierBadge } from "@/components/learn/LessonCard";
import { LessonQuiz } from "@/components/learn/LessonQuiz";
import { ReadinessScore } from "@/components/ReadinessScore";
import { RiskBadge } from "@/components/RiskBadge";
import {
  getGlossaryTermMap,
  getLessonBySlug,
  getRelatedLessons,
} from "@/lib/supabase/queries/lessons";
import { getLessonSupplement } from "@/lib/learn/supplements";
import type { LessonTier } from "@/lib/types";

interface Props {
  params: Promise<{ slug: string }>;
}

export default async function LessonPage({ params }: Props) {
  const { slug } = await params;
  const [lesson, termMap] = await Promise.all([
    getLessonBySlug(slug),
    getGlossaryTermMap(),
  ]);

  if (!lesson) notFound();

  const relatedLessons = await getRelatedLessons(lesson.related_slugs ?? []);
  const glossaryData = Object.fromEntries(termMap);
  const supplement = getLessonSupplement(lesson.slug);

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <nav className="flex items-center gap-2 text-sm text-gray-400 mb-8">
        <Link href="/learn" className="hover:text-gray-600 transition-colors">
          Học đấu thầu
        </Link>
        <i className="ti ti-chevron-right text-xs" aria-hidden="true" />
        <span className="text-gray-600">{lesson.title}</span>
      </nav>

      <header className="mb-8 space-y-3">
        <div className="flex items-center gap-2 flex-wrap">
          <TierBadge tier={lesson.tier as LessonTier} />
          {lesson.is_priority && (
            <span className="text-xs text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded">
              Ưu tiên học
            </span>
          )}
          {Array.isArray(lesson.fatal_errors) &&
            lesson.fatal_errors.length > 0 && (
              <span className="flex items-center gap-1 text-xs text-red-600 bg-red-50 border border-red-200 px-2 py-0.5 rounded">
                <i
                  className="ti ti-alert-triangle text-[11px]"
                  aria-hidden="true"
                />
                Có lỗi chí tử
              </span>
            )}
        </div>
        <h1 className="text-2xl font-medium text-gray-900">{lesson.title}</h1>
        {lesson.title_en && (
          <p className="text-sm text-gray-400 font-normal">{lesson.title_en}</p>
        )}
      </header>

      {lesson.objective && (
        <div className="flex gap-3 bg-blue-50 border border-blue-100 rounded-xl p-4 mb-8">
          <i
            className="ti ti-target text-blue-500 mt-0.5 shrink-0"
            aria-hidden="true"
          />
          <div>
            <p className="text-xs font-medium text-blue-700 mb-0.5 uppercase tracking-wide">
              Mục tiêu bài học
            </p>
            <ObjectiveContent objective={lesson.objective} />
          </div>
        </div>
      )}

      <LessonBody lesson={lesson} glossaryData={glossaryData} />

      {Array.isArray(lesson.fatal_errors) && lesson.fatal_errors.length > 0 && (
        <section className="mt-10 space-y-3">
          <h2 className="text-base font-medium text-gray-900 flex items-center gap-2">
            <i className="ti ti-skull text-red-500" aria-hidden="true" />
            Lỗi chí tử - bị loại ngay
          </h2>
          <div className="space-y-2">
            {lesson.fatal_errors.map((err, i) => (
              <div
                key={i}
                className="flex gap-3 bg-red-50 border border-red-100 rounded-xl p-4"
              >
                <i
                  className="ti ti-x text-red-500 mt-0.5 shrink-0"
                  aria-hidden="true"
                />
                <div>
                  <p className="text-sm text-red-800 leading-relaxed">
                    {err.description}
                  </p>
                  {err.law_reference && (
                    <p className="text-xs text-red-400 mt-1">
                      {err.law_reference}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {Array.isArray(lesson.common_mistakes) &&
        lesson.common_mistakes.length > 0 && (
          <section className="mt-10 space-y-3">
            <h2 className="text-base font-medium text-gray-900 flex items-center gap-2">
              <i
                className="ti ti-alert-circle text-amber-500"
                aria-hidden="true"
              />
              Sai sót thường gặp
            </h2>
            <div className="space-y-2">
              {lesson.common_mistakes.map((m, i) => (
                <div
                  key={i}
                  className={`flex gap-3 rounded-xl p-4 border ${
                    m.severity === "fatal"
                      ? "bg-red-50 border-red-100"
                      : m.severity === "high"
                        ? "bg-orange-50 border-orange-100"
                        : "bg-amber-50 border-amber-100"
                  }`}
                >
                  <i
                    className={`ti ti-alert-triangle mt-0.5 shrink-0 ${
                      m.severity === "fatal"
                        ? "text-red-500"
                        : m.severity === "high"
                          ? "text-orange-500"
                          : "text-amber-500"
                    }`}
                    aria-hidden="true"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="text-sm font-medium text-gray-800">
                        {m.title}
                      </p>
                      <RiskBadge level={m.severity} />
                    </div>
                    <p className="text-sm text-gray-600 mt-0.5 leading-relaxed">
                      {m.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

      {supplement.readinessScore && (
        <ReadinessScore
          scores={supplement.readinessScore.scores}
          conclusion={supplement.readinessScore.conclusion}
          priority={supplement.readinessScore.priority}
        />
      )}

      {supplement.caseFail && (
        <CaseFail
          title={supplement.caseFail.title}
          story={supplement.caseFail.story}
          lesson={supplement.caseFail.lesson}
        />
      )}

      {supplement.actionNextStep && (
        <ActionNextStep
          title={supplement.actionNextStep.title}
          items={supplement.actionNextStep.items}
        />
      )}

      {relatedLessons.length > 0 && (
        <section className="mt-12 space-y-4">
          <h2 className="text-base font-medium text-gray-900">
            Bài học liên quan
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {relatedLessons.map((l) => (
              <LessonCard key={l.id} lesson={l} />
            ))}
          </div>
        </section>
      )}

      {Array.isArray(lesson.quiz) && lesson.quiz.length > 0 && (
        <LessonQuiz quiz={lesson.quiz} />
      )}

      <div className="mt-12 pt-6 border-t border-gray-100">
        <Link
          href="/learn"
          className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-gray-700 transition-colors"
        >
          <i className="ti ti-arrow-left" aria-hidden="true" />
          Quay lại danh sách bài học
        </Link>
      </div>
    </div>
  );
}

function ObjectiveContent({ objective }: { objective: string }) {
  const lines = objective
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const intro = lines.find((line) => !line.startsWith("-"));
  const bullets = lines
    .filter((line) => line.startsWith("-"))
    .map((line) => line.replace(/^-\s*/, ""));

  if (!bullets.length) {
    return <p className="text-sm text-blue-800 leading-relaxed">{objective}</p>;
  }

  return (
    <div className="space-y-2">
      {intro && <p className="text-sm text-blue-800 leading-relaxed">{intro}</p>}
      <ul className="list-disc space-y-1 pl-5 text-sm text-blue-800">
        {bullets.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </div>
  );
}
