import Link from "next/link";
import { notFound } from "next/navigation";
import { getGlossaryTermBySlug } from "@/lib/supabase/queries/lessons";

interface Props {
  params: Promise<{ slug: string }>;
}

const CATEGORY_META: Record<string, { label: string; color: string }> = {
  financial: { label: "Tài chính", color: "text-emerald-700" },
  technical: { label: "Kỹ thuật", color: "text-blue-700" },
  legal: { label: "Pháp lý", color: "text-violet-700" },
  process: { label: "Quy trình", color: "text-orange-700" },
  compliance: { label: "Compliance", color: "text-red-700" },
};

function Section({
  icon,
  label,
  children,
  accent,
}: {
  icon: string;
  label: string;
  children: React.ReactNode;
  accent?: "blue" | "amber" | "green";
}) {
  const colors = {
    blue: "bg-blue-50 border-blue-100",
    amber: "bg-amber-50 border-amber-100",
    green: "bg-emerald-50 border-emerald-100",
  };
  const base = accent ? colors[accent] : "bg-gray-50 border-gray-100";

  return (
    <div className={`rounded-xl border p-4 space-y-2 ${base}`}>
      <p
        className={`text-xs font-medium uppercase tracking-wide flex items-center gap-1.5 ${
          accent === "blue"
            ? "text-blue-600"
            : accent === "amber"
              ? "text-amber-700"
              : accent === "green"
                ? "text-emerald-700"
                : "text-gray-500"
        }`}
      >
        <i className={`ti ${icon}`} aria-hidden="true" />
        {label}
      </p>
      <div
        className={`text-sm leading-relaxed ${
          accent === "blue"
            ? "text-blue-900"
            : accent === "amber"
              ? "text-amber-900"
              : accent === "green"
                ? "text-emerald-900"
                : "text-gray-700"
        }`}
      >
        {children}
      </div>
    </div>
  );
}

export default async function GlossaryTermPage({ params }: Props) {
  const { slug } = await params;
  const term = await getGlossaryTermBySlug(slug);
  if (!term) notFound();

  const catMeta = CATEGORY_META[term.category];

  return (
    <div className="max-w-2xl mx-auto px-4 py-10">
      <nav className="flex items-center gap-2 text-sm text-gray-400 mb-8">
        <Link href="/glossary" className="hover:text-gray-600 transition-colors">
          Glossary
        </Link>
        <i className="ti ti-chevron-right text-xs" aria-hidden="true" />
        <span className="text-gray-600">{term.term_vn}</span>
      </nav>

      <header className="mb-8 space-y-2">
        <div className="flex items-center gap-2 flex-wrap">
          {catMeta && (
            <span
              className={`text-xs font-medium px-2 py-0.5 rounded bg-gray-100 ${catMeta.color}`}
            >
              {catMeta.label}
            </span>
          )}
          {term.law_reference && (
            <span className="text-xs text-gray-400 bg-gray-50 border border-gray-200 px-2 py-0.5 rounded">
              {term.law_reference}
            </span>
          )}
        </div>
        <h1 className="text-2xl font-medium text-gray-900">{term.term_vn}</h1>
        <p className="text-base text-gray-400">{term.term_en}</p>
      </header>

      <p className="text-base text-gray-700 leading-relaxed mb-6">
        {term.short_definition}
      </p>

      <div className="space-y-4">
        <Section icon="ti-bulb" label="Nói đơn giản" accent="blue">
          {term.eli5}
        </Section>

        {term.practical_meaning && (
          <Section icon="ti-tool" label="Thực tế cần biết" accent="green">
            {term.practical_meaning}
          </Section>
        )}

        {term.risk_note && (
          <Section icon="ti-alert-triangle" label="Cảnh báo" accent="amber">
            {term.risk_note}
          </Section>
        )}

        {term.full_explanation && (
          <Section icon="ti-book" label="Giải thích đầy đủ">
            <p className="whitespace-pre-line">{term.full_explanation}</p>
          </Section>
        )}
      </div>

      {term.related_lesson_slugs?.length > 0 && (
        <div className="mt-8 space-y-3">
          <h2 className="text-sm font-medium text-gray-900 flex items-center gap-2">
            <i className="ti ti-school text-gray-400" aria-hidden="true" />
            Bài học liên quan
          </h2>
          <div className="flex flex-wrap gap-2">
            {term.related_lesson_slugs.map((relatedSlug) => (
              <Link
                key={relatedSlug}
                href={`/learn/${relatedSlug}`}
                className="text-xs text-blue-600 bg-blue-50 border border-blue-100 px-3 py-1.5 rounded-lg hover:bg-blue-100 transition-colors"
              >
                {relatedSlug.replace(/-/g, " ")}
                <i
                  className="ti ti-arrow-right text-[10px] ml-1"
                  aria-hidden="true"
                />
              </Link>
            ))}
          </div>
        </div>
      )}

      {term.related_term_slugs?.length > 0 && (
        <div className="mt-6 space-y-3">
          <h2 className="text-sm font-medium text-gray-900 flex items-center gap-2">
            <i className="ti ti-link text-gray-400" aria-hidden="true" />
            Thuật ngữ liên quan
          </h2>
          <div className="flex flex-wrap gap-2">
            {term.related_term_slugs.map((relatedSlug) => (
              <Link
                key={relatedSlug}
                href={`/glossary/${relatedSlug}`}
                className="text-xs text-gray-600 bg-gray-50 border border-gray-200 px-3 py-1.5 rounded-lg hover:border-gray-400 transition-colors"
              >
                {relatedSlug.replace(/-/g, " ")}
              </Link>
            ))}
          </div>
        </div>
      )}

      <div className="mt-12 pt-6 border-t border-gray-100">
        <Link
          href="/glossary"
          className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-gray-700 transition-colors"
        >
          <i className="ti ti-arrow-left" aria-hidden="true" />
          Quay lại Glossary
        </Link>
      </div>
    </div>
  );
}
