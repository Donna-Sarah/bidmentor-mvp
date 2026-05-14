interface CaseFailProps {
  title: string;
  story: string;
  lesson: string;
}

export function CaseFail({ title, story, lesson }: CaseFailProps) {
  return (
    <section className="mt-10 rounded-xl border border-red-100 bg-red-50 p-4">
      <p className="text-xs font-bold uppercase tracking-wide text-red-700">
        Case Fail — 60 giây
      </p>
      <h2 className="mt-2 text-base font-semibold text-red-950">{title}</h2>
      <p className="mt-2 text-sm leading-relaxed text-red-900">{story}</p>
      <p className="mt-3 text-sm leading-relaxed text-red-950">
        <strong>Bài học:</strong> {lesson}
      </p>
    </section>
  );
}
