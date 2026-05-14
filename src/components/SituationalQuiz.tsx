"use client";

import { useState } from "react";

interface SituationalQuizOption {
  label: string;
  text: string;
}

interface SituationalQuizProps {
  question: string;
  options: SituationalQuizOption[];
  answer: string;
  explanation: string;
}

export function SituationalQuiz({
  question,
  options,
  answer,
  explanation,
}: SituationalQuizProps) {
  const [selected, setSelected] = useState<string | null>(null);
  const [hasSubmitted, setHasSubmitted] = useState(false);

  return (
    <div className="rounded-xl border border-gray-100 bg-white p-4">
      <p className="text-sm font-medium leading-relaxed text-gray-900">
        {question}
      </p>
      <div className="mt-3 space-y-2">
        {options.map((option) => {
          const isSelected = selected === option.label;
          const isCorrect = option.label === answer;
          const shouldShowCorrect = hasSubmitted && isCorrect;
          const shouldShowWrong = hasSubmitted && isSelected && !isCorrect;

          return (
            <button
              key={option.label}
              type="button"
              onClick={() => {
                setSelected(option.label);
                setHasSubmitted(false);
              }}
              className={`w-full rounded-lg border px-3 py-2 text-left text-sm leading-relaxed transition-colors ${
                shouldShowCorrect
                  ? "border-emerald-200 bg-emerald-50 text-emerald-900"
                  : shouldShowWrong
                    ? "border-red-200 bg-red-50 text-red-900"
                    : isSelected
                      ? "border-blue-200 bg-blue-50 text-blue-900"
                      : "border-gray-200 bg-white text-gray-700 hover:border-gray-300 hover:bg-gray-50"
              }`}
            >
              <span className="font-semibold">{option.label})</span> {option.text}
            </button>
          );
        })}
      </div>
      <button
        type="button"
        disabled={!selected}
        onClick={() => setHasSubmitted(true)}
        className="mt-3 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-gray-300"
      >
        Kiểm tra
      </button>
      {hasSubmitted && (
        <div className="mt-3 rounded-lg border border-blue-100 bg-blue-50 p-3">
          <p className="text-xs font-medium uppercase tracking-wide text-blue-700">
            Giải thích
          </p>
          <p className="mt-1 text-sm leading-relaxed text-blue-900">
            {explanation}
          </p>
        </div>
      )}
    </div>
  );
}
