"use client";

import Link from "next/link";
import { useState } from "react";

type QuickScanRecommendation = "GO" | "NO_GO" | "CAUTION";

interface QuickScanSuccess {
  recommendation: QuickScanRecommendation;
  summary: string;
  fatalErrors: string[];
  risks: string[];
  workload: string;
}

function isQuickScanSuccess(data: unknown): data is QuickScanSuccess {
  if (!data || typeof data !== "object") return false;
  const o = data as Record<string, unknown>;
  return (
    (o.recommendation === "GO" ||
      o.recommendation === "NO_GO" ||
      o.recommendation === "CAUTION") &&
    typeof o.summary === "string" &&
    Array.isArray(o.fatalErrors) &&
    o.fatalErrors.every((x) => typeof x === "string") &&
    Array.isArray(o.risks) &&
    o.risks.every((x) => typeof x === "string") &&
    typeof o.workload === "string"
  );
}

function recommendationStyles(r: QuickScanRecommendation): string {
  switch (r) {
    case "GO":
      return "bg-emerald-100 text-emerald-900 ring-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-100 dark:ring-emerald-800";
    case "NO_GO":
      return "bg-rose-100 text-rose-900 ring-rose-200 dark:bg-rose-950/50 dark:text-rose-100 dark:ring-rose-800";
    case "CAUTION":
      return "bg-amber-100 text-amber-950 ring-amber-200 dark:bg-amber-950/40 dark:text-amber-100 dark:ring-amber-800";
  }
}

export default function AnalyzePage() {
  const [documentText, setDocumentText] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<QuickScanSuccess | null>(null);

  async function handleAnalyze() {
    setError(null);
    setResult(null);
    setLoading(true);
    try {
      const response = await fetch("/api/ai/quick-scan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ documentText }),
      });

      const data: unknown = await response.json().catch(() => null);

      if (!response.ok) {
        const message =
          data &&
          typeof data === "object" &&
          "error" in data &&
          typeof (data as { error: unknown }).error === "string"
            ? (data as { error: string }).error
            : `Request failed (${response.status}).`;
        setError(message);
        return;
      }

      if (!isQuickScanSuccess(data)) {
        setError("Unexpected response shape from the server.");
        return;
      }

      setResult(data);
    } catch {
      setError("Network error - check your connection and try again.");
    } finally {
      setLoading(false);
    }
  }

  const trimmed = documentText.trim();
  const canSubmit = trimmed.length > 0 && !loading;

  return (
    <main className="min-h-full flex-1 bg-zinc-50 text-zinc-900 dark:bg-zinc-950 dark:text-zinc-100">
      <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6 sm:py-14">
        <div className="mb-10 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">
              BidMentor
            </p>
            <h1 className="mt-1 text-2xl font-semibold tracking-tight sm:text-3xl">
              Quick Scan
            </h1>
            <p className="mt-2 max-w-xl text-sm leading-relaxed text-zinc-600 dark:text-zinc-400">
              Paste HSMT text for a fast GO / NO-GO style read - fatal issues,
              risks, and a rough workload sense. AI suggests; you decide.
            </p>
          </div>
          <Link
            href="/"
            className="text-sm font-medium text-zinc-600 underline-offset-4 hover:text-zinc-900 hover:underline dark:text-zinc-400 dark:hover:text-zinc-100"
          >
            ← Home
          </Link>
        </div>

        <section className="space-y-4 rounded-2xl border border-zinc-200/80 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-900 sm:p-6">
          <label htmlFor="hsmt" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
            HSMT content
          </label>
          <textarea
            id="hsmt"
            value={documentText}
            onChange={(e) => setDocumentText(e.target.value)}
            rows={14}
            placeholder="Paste tender / HSMT text here…"
            className="w-full resize-y rounded-xl border border-zinc-200 bg-zinc-50/80 px-3 py-3 text-sm leading-relaxed text-zinc-900 placeholder:text-zinc-400 focus:border-zinc-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-zinc-300/60 dark:border-zinc-700 dark:bg-zinc-950/50 dark:text-zinc-100 dark:placeholder:text-zinc-500 dark:focus:border-zinc-500 dark:focus:bg-zinc-950 dark:focus:ring-zinc-600/50"
            disabled={loading}
          />
          <div className="flex flex-wrap items-center gap-3 pt-1">
            <button
              type="button"
              onClick={handleAnalyze}
              disabled={!canSubmit}
              className="inline-flex min-h-10 items-center justify-center rounded-full bg-zinc-900 px-5 text-sm font-medium text-white transition hover:bg-zinc-800 disabled:cursor-not-allowed disabled:opacity-40 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-white"
            >
              {loading ? "Analyzing…" : "Analyze"}
            </button>
            {loading && (
              <span className="text-sm text-zinc-500 dark:text-zinc-400" aria-live="polite">
                This can take a little while.
              </span>
            )}
          </div>
        </section>

        {error && (
          <div
            role="alert"
            className="mt-8 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-900 dark:border-rose-900/60 dark:bg-rose-950/40 dark:text-rose-100"
          >
            {error}
          </div>
        )}

        {result && (
          <section className="mt-10 space-y-8">
            <h2 className="text-lg font-semibold tracking-tight">Results</h2>

            <div className="flex flex-wrap items-center gap-3">
              <span className="text-sm font-medium text-zinc-500 dark:text-zinc-400">
                Recommendation
              </span>
              <span
                className={`inline-flex rounded-full px-3 py-1 text-sm font-semibold ring-1 ring-inset ${recommendationStyles(result.recommendation)}`}
              >
                {result.recommendation.replace("_", " ")}
              </span>
            </div>

            <div>
              <h3 className="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Summary
              </h3>
              <p className="mt-2 whitespace-pre-wrap text-sm leading-relaxed text-zinc-800 dark:text-zinc-200">
                {result.summary}
              </p>
            </div>

            <div>
              <h3 className="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Fatal errors
              </h3>
              {result.fatalErrors.length === 0 ? (
                <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-400">
                  None flagged in this pass.
                </p>
              ) : (
                <ul className="mt-3 list-inside list-disc space-y-2 text-sm leading-relaxed text-zinc-800 dark:text-zinc-200">
                  {result.fatalErrors.map((item, i) => (
                    <li key={`fatal-${i}`}>{item}</li>
                  ))}
                </ul>
              )}
            </div>

            <div>
              <h3 className="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Risks
              </h3>
              {result.risks.length === 0 ? (
                <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-400">
                  None listed beyond the summary.
                </p>
              ) : (
                <ul className="mt-3 list-inside list-disc space-y-2 text-sm leading-relaxed text-zinc-800 dark:text-zinc-200">
                  {result.risks.map((item, i) => (
                    <li key={`risk-${i}`}>{item}</li>
                  ))}
                </ul>
              )}
            </div>

            <div className="rounded-xl border border-zinc-200 bg-white px-4 py-4 dark:border-zinc-800 dark:bg-zinc-900">
              <h3 className="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Workload estimate
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-zinc-800 dark:text-zinc-200">
                {result.workload}
              </p>
            </div>
          </section>
        )}
      </div>
    </main>
  );
}
