"use client";

import { useState } from "react";
import type { LessonQuizQuestion } from "@/lib/types";

interface LessonQuizProps {
  quiz: LessonQuizQuestion[];
}

export function LessonQuiz({ quiz }: LessonQuizProps) {
  const [selectedAnswers, setSelectedAnswers] = useState<Record<number, string>>(
    {},
  );

  return (
    <section className="mt-12 space-y-4">
      <div className="space-y-1">
        <h2 className="text-base font-medium text-gray-900 flex items-center gap-2">
          <i className="ti ti-clipboard-check text-blue-500" aria-hidden="true" />
          Kiểm tra nhanh
        </h2>
        <p className="text-sm text-gray-500">
          Chọn một đáp án để xem giải thích. Không tính điểm, chỉ để bạn tự kiểm
          tra hiểu bài.
        </p>
      </div>

      <div className="space-y-4">
        {quiz.map((question, questionIndex) => {
          const selectedAnswer = selectedAnswers[questionIndex];
          const hasAnswered = Boolean(selectedAnswer);

          return (
            <div
              key={`${question.question}-${questionIndex}`}
              className="rounded-xl border border-gray-100 bg-white p-4 space-y-3"
            >
              <p className="text-sm font-medium text-gray-900 leading-relaxed">
                {questionIndex + 1}. {question.question}
              </p>

              <div className="space-y-2">
                {question.options.map((option) => {
                  const isSelected = selectedAnswer === option;
                  const isCorrect = option === question.correct_answer;
                  const shouldShowCorrect = hasAnswered && isCorrect;
                  const shouldShowIncorrect =
                    hasAnswered && isSelected && !isCorrect;

                  return (
                    <button
                      key={option}
                      type="button"
                      onClick={() =>
                        setSelectedAnswers((prev) => ({
                          ...prev,
                          [questionIndex]: option,
                        }))
                      }
                      className={`w-full rounded-lg border px-3 py-2 text-left text-sm leading-relaxed transition-colors ${
                        shouldShowCorrect
                          ? "border-emerald-200 bg-emerald-50 text-emerald-900"
                          : shouldShowIncorrect
                            ? "border-red-200 bg-red-50 text-red-900"
                            : isSelected
                              ? "border-blue-200 bg-blue-50 text-blue-900"
                              : "border-gray-200 bg-white text-gray-700 hover:border-gray-300 hover:bg-gray-50"
                      }`}
                    >
                      <span className="flex items-start gap-2">
                        <span
                          className={`mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full border text-[10px] ${
                            shouldShowCorrect
                              ? "border-emerald-500 bg-emerald-500 text-white"
                              : shouldShowIncorrect
                                ? "border-red-500 bg-red-500 text-white"
                                : "border-gray-300 text-transparent"
                          }`}
                        >
                          {shouldShowCorrect ? "✓" : shouldShowIncorrect ? "×" : ""}
                        </span>
                        <span>{option}</span>
                      </span>
                    </button>
                  );
                })}
              </div>

              {hasAnswered && (
                <div className="rounded-lg border border-blue-100 bg-blue-50 p-3">
                  <p className="text-xs font-medium uppercase tracking-wide text-blue-700">
                    Giải thích
                  </p>
                  <p className="mt-1 text-sm leading-relaxed text-blue-900">
                    {question.explanation}
                  </p>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
