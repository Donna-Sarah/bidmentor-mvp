"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { GlossaryTerm } from "@/lib/types";

const CATEGORY_META: Record<
  string,
  { label: string; color: string; bg: string; border: string }
> = {
  financial: {
    label: "Tài chính",
    color: "text-emerald-700",
    bg: "bg-emerald-50",
    border: "border-emerald-200",
  },
  technical: {
    label: "Kỹ thuật",
    color: "text-blue-700",
    bg: "bg-blue-50",
    border: "border-blue-200",
  },
  legal: {
    label: "Pháp lý",
    color: "text-violet-700",
    bg: "bg-violet-50",
    border: "border-violet-200",
  },
  process: {
    label: "Quy trình",
    color: "text-orange-700",
    bg: "bg-orange-50",
    border: "border-orange-200",
  },
  compliance: {
    label: "Compliance",
    color: "text-red-700",
    bg: "bg-red-50",
    border: "border-red-200",
  },
};

const ALL_CATEGORIES = Object.keys(CATEGORY_META);

function CategoryBadge({ category }: { category: string }) {
  const meta = CATEGORY_META[category] ?? {
    label: category,
    color: "text-gray-600",
    bg: "bg-gray-50",
    border: "border-gray-200",
  };

  return (
    <span
      className={`inline-block text-xs font-medium px-2 py-0.5 rounded border ${meta.color} ${meta.bg} ${meta.border}`}
    >
      {meta.label}
    </span>
  );
}

function TermRow({ term }: { term: GlossaryTerm }) {
  return (
    <Link
      href={`/glossary/${term.slug}`}
      className="group flex items-start gap-4 py-4 border-b border-gray-100 last:border-0 hover:bg-gray-50/50 -mx-2 px-2 rounded-lg transition-colors"
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline gap-2 flex-wrap mb-1">
          <span className="text-sm font-medium text-gray-900 group-hover:text-gray-700">
            {term.term_vn}
          </span>
          <span className="text-xs text-gray-400">{term.term_en}</span>
        </div>
        <p className="text-xs text-gray-500 leading-relaxed line-clamp-2">
          {term.short_definition}
        </p>
        {term.risk_note && (
          <p className="text-xs text-amber-600 mt-1 flex items-center gap-1">
            <i className="ti ti-alert-triangle text-[10px]" aria-hidden="true" />
            {term.risk_note.slice(0, 80)}
            {term.risk_note.length > 80 ? "..." : ""}
          </p>
        )}
      </div>

      <div className="flex items-center gap-2 shrink-0">
        <CategoryBadge category={term.category} />
        <i
          className="ti ti-arrow-right text-sm text-gray-300 group-hover:text-gray-500 group-hover:translate-x-0.5 transition-transform"
          aria-hidden="true"
        />
      </div>
    </Link>
  );
}

interface GlossaryClientProps {
  terms: GlossaryTerm[];
}

export function GlossaryClient({ terms }: GlossaryClientProps) {
  const [query, setQuery] = useState("");
  const [activeCategory, setActiveCategory] = useState<string | null>(null);

  const filtered = useMemo(() => {
    let result = terms;

    if (activeCategory) {
      result = result.filter((t) => t.category === activeCategory);
    }

    if (query.trim()) {
      const q = query.trim().toLowerCase();
      result = result.filter(
        (t) =>
          t.term_vn.toLowerCase().includes(q) ||
          t.term_en.toLowerCase().includes(q) ||
          t.short_definition.toLowerCase().includes(q),
      );
    }

    return result;
  }, [terms, query, activeCategory]);

  const grouped = useMemo(() => {
    const map = new Map<string, GlossaryTerm[]>();
    for (const term of filtered) {
      const letter = term.term_vn[0].toUpperCase();
      if (!map.has(letter)) map.set(letter, []);
      map.get(letter)!.push(term);
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [filtered]);

  return (
    <div className="space-y-6">
      <div className="relative">
        <i
          className="ti ti-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-base"
          aria-hidden="true"
        />
        <input
          type="text"
          placeholder="Tìm thuật ngữ - VD: bid bond, bảo lãnh, clarification..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 text-sm border border-gray-200 rounded-xl bg-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-blue-300 transition"
        />
        {query && (
          <button
            onClick={() => setQuery("")}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            aria-label="Xóa tìm kiếm"
          >
            <i className="ti ti-x text-sm" aria-hidden="true" />
          </button>
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setActiveCategory(null)}
          className={`text-xs font-medium px-3 py-1.5 rounded-full border transition-colors ${
            !activeCategory
              ? "bg-gray-900 text-white border-gray-900"
              : "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
          }`}
        >
          Tất cả ({terms.length})
        </button>
        {ALL_CATEGORIES.map((cat) => {
          const count = terms.filter((t) => t.category === cat).length;
          if (!count) return null;

          const meta = CATEGORY_META[cat];
          const isActive = activeCategory === cat;
          return (
            <button
              key={cat}
              onClick={() => setActiveCategory(isActive ? null : cat)}
              className={`text-xs font-medium px-3 py-1.5 rounded-full border transition-colors ${
                isActive
                  ? `${meta.bg} ${meta.color} ${meta.border}`
                  : "bg-white text-gray-600 border-gray-200 hover:border-gray-400"
              }`}
            >
              {meta.label} ({count})
            </button>
          );
        })}
      </div>

      {(query || activeCategory) && (
        <p className="text-xs text-gray-400">
          {filtered.length} kết quả
          {query ? ` cho "${query}"` : ""}
          {activeCategory ? ` trong ${CATEGORY_META[activeCategory]?.label}` : ""}
        </p>
      )}

      {grouped.length > 0 ? (
        <div className="space-y-6">
          {grouped.map(([letter, letterTerms]) => (
            <div key={letter}>
              <p className="text-xs font-medium text-gray-400 uppercase tracking-widest mb-2 px-2">
                {letter}
              </p>
              <div className="bg-white border border-gray-100 rounded-xl px-2">
                {letterTerms.map((term) => (
                  <TermRow key={term.id} term={term} />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 text-gray-400">
          <i className="ti ti-search-off text-3xl mb-3 block" aria-hidden="true" />
          <p className="text-sm">Không tìm thấy thuật ngữ nào.</p>
          <button
            onClick={() => {
              setQuery("");
              setActiveCategory(null);
            }}
            className="text-xs text-blue-500 mt-2 hover:underline"
          >
            Xóa bộ lọc
          </button>
        </div>
      )}
    </div>
  );
}
