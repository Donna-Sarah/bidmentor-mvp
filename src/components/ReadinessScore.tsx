interface ReadinessScoreItem {
  label: string;
  score: number;
  note?: string;
}

interface ReadinessScoreProps {
  scores: ReadinessScoreItem[];
  conclusion: string;
  priority?: string;
}

export function ReadinessScore({
  scores,
  conclusion,
  priority,
}: ReadinessScoreProps) {
  if (!scores.length) return null;

  const average = Math.round(
    scores.reduce((total, item) => total + item.score, 0) / scores.length,
  );

  return (
    <section className="mt-10 rounded-xl border border-gray-100 bg-white p-4">
      <h2 className="text-base font-semibold text-gray-900">
        Readiness Score
      </h2>
      <div className="mt-4 space-y-3">
        {scores.map((item) => (
          <div key={item.label} className="space-y-1">
            <div className="flex items-center justify-between gap-3 text-sm">
              <span className="font-medium text-gray-800">{item.label}</span>
              <span className="font-semibold text-gray-900">{item.score}/100</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-gray-100">
              <div
                className={`h-full rounded-full ${getScoreColor(item.score)}`}
                style={{ width: `${Math.max(0, Math.min(100, item.score))}%` }}
              />
            </div>
            {item.note && (
              <p className="text-xs leading-relaxed text-gray-500">{item.note}</p>
            )}
          </div>
        ))}
      </div>
      <div className="mt-4 rounded-lg bg-gray-50 p-3 text-sm leading-relaxed text-gray-800">
        <p>
          <strong>Tổng thể:</strong> {average}/100 — {conclusion}
        </p>
        {priority && (
          <p className="mt-1">
            <strong>Điểm yếu nhất:</strong> {priority}
          </p>
        )}
      </div>
    </section>
  );
}

function getScoreColor(score: number): string {
  if (score < 50) return "bg-red-500";
  if (score < 75) return "bg-orange-500";
  if (score < 85) return "bg-yellow-500";
  return "bg-emerald-500";
}
