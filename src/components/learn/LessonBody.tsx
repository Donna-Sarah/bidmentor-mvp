"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import type { GlossaryTerm, Lesson } from "@/lib/types";

interface TooltipState {
  term: GlossaryTerm;
  anchorRect: DOMRect;
}

interface LessonBodyProps {
  lesson: Lesson;
  glossaryData: Record<string, GlossaryTerm>;
}

function GlossaryTooltip({
  state,
  onClose,
}: {
  state: TooltipState;
  onClose: () => void;
}) {
  const { term, anchorRect } = state;
  const tooltipRef = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState({ top: 0, left: 0 });

  useEffect(() => {
    if (!tooltipRef.current) return;

    const tw = tooltipRef.current.offsetWidth || 320;
    const left = Math.min(
      anchorRect.left + window.scrollX,
      window.innerWidth + window.scrollX - tw - 16,
    );
    setPos({
      top: anchorRect.bottom + window.scrollY + 8,
      left: Math.max(16, left),
    });
  }, [anchorRect]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (
        tooltipRef.current &&
        !tooltipRef.current.contains(e.target as Node)
      ) {
        onClose();
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [onClose]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [onClose]);

  return (
    <div
      ref={tooltipRef}
      role="tooltip"
      className="fixed z-50 w-80 bg-white border border-gray-200 rounded-2xl shadow-lg p-4 space-y-3 text-sm"
      style={{ top: pos.top, left: pos.left }}
    >
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-medium text-gray-900 text-sm leading-tight">
            {term.term_vn}
          </p>
          <p className="text-xs text-gray-400 mt-0.5">{term.term_en}</p>
        </div>
        <button
          onClick={onClose}
          className="shrink-0 text-gray-300 hover:text-gray-500 p-0.5"
          aria-label="Đóng tooltip"
        >
          <i className="ti ti-x text-base" aria-hidden="true" />
        </button>
      </div>

      <div className="bg-blue-50 rounded-lg p-3">
        <p className="text-xs font-medium text-blue-600 mb-1 uppercase tracking-wide">
          Nói đơn giản
        </p>
        <p className="text-sm text-blue-900 leading-relaxed">{term.eli5}</p>
      </div>

      {term.risk_note && (
        <div className="flex gap-2 bg-amber-50 rounded-lg p-3">
          <i
            className="ti ti-alert-triangle text-amber-500 text-base shrink-0 mt-0.5"
            aria-hidden="true"
          />
          <p className="text-xs text-amber-800 leading-relaxed">
            {term.risk_note}
          </p>
        </div>
      )}

      {term.practical_meaning && (
        <div>
          <p className="text-xs font-medium text-gray-500 mb-1">
            Thực tế cần biết
          </p>
          <p className="text-xs text-gray-600 leading-relaxed">
            {term.practical_meaning}
          </p>
        </div>
      )}

      <Link
        href={`/glossary/${term.slug}`}
        className="inline-flex items-center gap-1.5 text-xs text-blue-600 hover:text-blue-800 font-medium"
        onClick={onClose}
      >
        Xem đầy đủ
        <i className="ti ti-arrow-right text-[10px]" aria-hidden="true" />
      </Link>
    </div>
  );
}

function highlightGlossaryTerms(
  text: string,
  glossaryData: Record<string, GlossaryTerm>,
): string {
  const protectedBlocks: string[] = [];
  let result = text.replace(/<(pre|code)\b[\s\S]*?<\/\1>/gi, (block) => {
    const token = `@@PROTECTED_HTML_${protectedBlocks.length}@@`;
    protectedBlocks.push(block);
    return token;
  });

  const knownTerms = Array.from(
    new Set(
      Object.values(glossaryData).flatMap((t) => [t.term_vn, t.term_en]),
    ),
  ).sort((a, b) => b.length - a.length);

  for (const term of knownTerms) {
    const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`(?<![<"'])\\b(${escaped})\\b(?![^<]*>)`, "gi");
    result = result.replace(
      regex,
      `<mark class="glossary-term" data-term="${term.toLowerCase()}">$1</mark>`,
    );
  }
  return protectedBlocks.reduce(
    (html, block, index) => html.replace(`@@PROTECTED_HTML_${index}@@`, block),
    result,
  );
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function formatInlineMarkdown(value: string): string {
  const codeSpans: string[] = [];
  let escaped = escapeHtml(value).replace(/`([^`]+)`/g, (_, code: string) => {
    const token = `@@CODE_${codeSpans.length}@@`;
    codeSpans.push(`<code>${code}</code>`);
    return token;
  });

  escaped = escaped
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/\*([^*]+)\*/g, "<em>$1</em>");

  return codeSpans.reduce(
    (result, code, index) => result.replace(`@@CODE_${index}@@`, code),
    escaped,
  );
}

function isTableDivider(line: string): boolean {
  return /^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$/.test(line);
}

function renderTable(lines: string[]): string {
  const [headerLine, , ...bodyLines] = lines;
  const parseCells = (line: string) =>
    line
      .trim()
      .replace(/^\|/, "")
      .replace(/\|$/, "")
      .split("|")
      .map((cell) => cell.trim());

  const headers = parseCells(headerLine);
  const rows = bodyLines.map(parseCells);

  return `<div class="lesson-table-wrap"><table><thead><tr>${headers
    .map((cell) => `<th>${formatInlineMarkdown(cell)}</th>`)
    .join("")}</tr></thead><tbody>${rows
    .map(
      (row) =>
        `<tr>${row
          .map((cell) => `<td>${formatInlineMarkdown(cell)}</td>`)
          .join("")}</tr>`,
    )
    .join("")}</tbody></table></div>`;
}

function isBlockStart(line: string, nextLine?: string): boolean {
  return (
    /^```/.test(line) ||
    /^#{2,4}\s+/.test(line) ||
    /^---+$/.test(line.trim()) ||
    /^>\s?/.test(line) ||
    /^[-*]\s+/.test(line) ||
    /^\d+\.\s+/.test(line) ||
    (line.trim().startsWith("|") && Boolean(nextLine && isTableDivider(nextLine)))
  );
}

function renderLessonMarkdown(markdown: string): string {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  const html: string[] = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();
    const nextLine = lines[i + 1]?.trim();

    if (!trimmed) {
      i += 1;
      continue;
    }

    if (trimmed.startsWith("```")) {
      const codeLines: string[] = [];
      i += 1;
      while (i < lines.length && !lines[i].trim().startsWith("```")) {
        codeLines.push(lines[i]);
        i += 1;
      }
      if (i < lines.length) i += 1;
      html.push(`<pre><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
      continue;
    }

    if (/^---+$/.test(trimmed)) {
      html.push("<hr />");
      i += 1;
      continue;
    }

    if (trimmed.startsWith("|") && nextLine && isTableDivider(nextLine)) {
      const tableLines = [trimmed, nextLine];
      i += 2;
      while (i < lines.length && lines[i].trim().startsWith("|")) {
        tableLines.push(lines[i].trim());
        i += 1;
      }
      html.push(renderTable(tableLines));
      continue;
    }

    const heading = trimmed.match(/^(#{2,4})\s+(.+)$/);
    if (heading) {
      const level = heading[1].length;
      html.push(`<h${level}>${formatInlineMarkdown(heading[2])}</h${level}>`);
      i += 1;
      continue;
    }

    if (/^>\s?/.test(trimmed)) {
      const quoteLines: string[] = [];
      while (i < lines.length && /^>\s?/.test(lines[i].trim())) {
        quoteLines.push(lines[i].trim().replace(/^>\s?/, ""));
        i += 1;
      }
      html.push(
        `<blockquote><p>${formatInlineMarkdown(quoteLines.join(" "))}</p></blockquote>`,
      );
      continue;
    }

    if (/^[-*]\s+/.test(trimmed)) {
      const items: string[] = [];
      while (i < lines.length && /^[-*]\s+/.test(lines[i].trim())) {
        const item = lines[i]
          .trim()
          .replace(/^[-*]\s+\[[ xX]\]\s+/, "")
          .replace(/^[-*]\s+/, "");
        items.push(`<li>${formatInlineMarkdown(item)}</li>`);
        i += 1;
      }
      html.push(`<ul>${items.join("")}</ul>`);
      continue;
    }

    if (/^\d+\.\s+/.test(trimmed)) {
      const items: string[] = [];
      while (i < lines.length && /^\d+\.\s+/.test(lines[i].trim())) {
        items.push(
          `<li>${formatInlineMarkdown(lines[i].trim().replace(/^\d+\.\s+/, ""))}</li>`,
        );
        i += 1;
      }
      html.push(`<ol>${items.join("")}</ol>`);
      continue;
    }

    const paragraphLines = [trimmed];
    i += 1;
    while (
      i < lines.length &&
      lines[i].trim() &&
      !isBlockStart(lines[i].trim(), lines[i + 1]?.trim())
    ) {
      paragraphLines.push(lines[i].trim());
      i += 1;
    }
    html.push(`<p>${formatInlineMarkdown(paragraphLines.join(" "))}</p>`);
  }

  return html.join("\n");
}

export function LessonBody({ lesson, glossaryData }: LessonBodyProps) {
  const [tooltip, setTooltip] = useState<TooltipState | null>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  const handleTermClick = useCallback(
    (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const mark = target.closest("mark.glossary-term") as HTMLElement | null;
      if (!mark) return;

      e.stopPropagation();
      const termKey = mark.dataset.term ?? "";
      const term =
        glossaryData[termKey] ??
        glossaryData[termKey.toLowerCase()] ??
        Object.values(glossaryData).find(
          (t) =>
            t.term_vn.toLowerCase() === termKey ||
            t.term_en.toLowerCase() === termKey,
        );

      if (term) setTooltip({ term, anchorRect: mark.getBoundingClientRect() });
    },
    [glossaryData],
  );

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;

    el.addEventListener("click", handleTermClick);
    return () => el.removeEventListener("click", handleTermClick);
  }, [handleTermClick]);

  useEffect(() => {
    if (!tooltip) return;

    const handler = () => setTooltip(null);
    window.addEventListener("scroll", handler, { passive: true });
    return () => window.removeEventListener("scroll", handler);
  }, [tooltip]);

  const rawText = lesson.content_mdx ?? lesson.explanation ?? "";
  const rendered = renderLessonMarkdown(rawText);
  const highlighted = highlightGlossaryTerms(rendered, glossaryData);

  return (
    <>
      <div className="flex items-center gap-2 text-xs text-gray-400 mb-6 bg-gray-50 border border-gray-100 rounded-lg px-3 py-2">
        <i className="ti ti-hand-click text-gray-400" aria-hidden="true" />
        <span>
          Nhấn vào{" "}
          <mark className="glossary-term bg-blue-100 text-blue-800 px-1 rounded cursor-pointer">
            thuật ngữ được highlight
          </mark>{" "}
          để xem giải thích ngay
        </span>
      </div>

      <div
        ref={contentRef}
        className="lesson-content prose prose-gray max-w-none"
        dangerouslySetInnerHTML={{ __html: highlighted }}
      />

      {tooltip && (
        <GlossaryTooltip state={tooltip} onClose={() => setTooltip(null)} />
      )}

      <style>{`
        .lesson-content mark.glossary-term { background:#dbeafe;color:#1e40af;border-radius:3px;padding:0 3px;cursor:pointer;font-style:normal;text-decoration:underline;text-decoration-style:dotted;text-underline-offset:2px;transition:background .1s; }
        .lesson-content mark.glossary-term:hover { background:#bfdbfe; }
        .lesson-content { line-height:1.75;color:#374151; }
        .lesson-content h2 { font-size:1.125rem;font-weight:500;color:#111827;margin-top:2rem;margin-bottom:.75rem; }
        .lesson-content h3 { font-size:1rem;font-weight:500;color:#1f2937;margin-top:1.5rem;margin-bottom:.5rem; }
        .lesson-content h4 { font-size:.9375rem;font-weight:600;color:#374151;margin-top:1rem;margin-bottom:.375rem; }
        .lesson-content p { margin-bottom:1rem; }
        .lesson-content ul,.lesson-content ol { padding-left:1.25rem;margin-bottom:1rem; }
        .lesson-content ul { list-style:disc; }
        .lesson-content ol { list-style:decimal; }
        .lesson-content li { margin-bottom:.375rem; }
        .lesson-content blockquote { border-left:3px solid #e5e7eb;padding-left:1rem;color:#6b7280;margin:1.5rem 0;font-style:italic; }
        .lesson-content blockquote p { margin-bottom:0; }
        .lesson-content strong { font-weight:600;color:#1f2937; }
        .lesson-content em { font-style:italic; }
        .lesson-content code { background:#f3f4f6;padding:1px 5px;border-radius:4px;font-size:.875em; }
        .lesson-content pre { background:#111827;color:#f9fafb;border-radius:12px;padding:1rem;overflow-x:auto;margin:1.25rem 0;font-family:"Segoe UI",Arial,sans-serif;font-size:.875rem;line-height:1.65;white-space:pre-wrap; }
        .lesson-content pre code { background:transparent;color:inherit;padding:0;border-radius:0;font-family:inherit;font-size:inherit; }
        .lesson-content hr { border:0;border-top:1px solid #e5e7eb;margin:1.75rem 0; }
        .lesson-content .lesson-table-wrap { overflow-x:auto;margin:1.25rem 0;border:1px solid #e5e7eb;border-radius:12px; }
        .lesson-content table { width:100%;border-collapse:collapse;background:#fff;font-size:.875rem; }
        .lesson-content th { background:#f9fafb;color:#374151;font-weight:600;text-align:left; }
        .lesson-content th,.lesson-content td { border-bottom:1px solid #e5e7eb;padding:.625rem .75rem;vertical-align:top; }
        .lesson-content tr:last-child td { border-bottom:0; }
      `}</style>
    </>
  );
}
