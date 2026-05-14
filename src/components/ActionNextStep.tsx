interface ActionNextStepProps {
  items: string[];
  title?: string;
}

export function ActionNextStep({
  items,
  title = "Bạn nên làm gì ngay sau bài này?",
}: ActionNextStepProps) {
  if (!items.length) return null;

  return (
    <section className="mt-10 rounded-xl border border-emerald-100 border-l-4 border-l-[#16A34A] bg-emerald-50 p-4">
      <h2 className="text-base font-semibold text-emerald-950">{title}</h2>
      <ol className="mt-3 list-decimal space-y-2 pl-5 text-sm leading-relaxed text-emerald-950">
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ol>
    </section>
  );
}
