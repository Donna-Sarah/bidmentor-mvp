import { GlossaryClient } from "@/components/learn/GlossaryClient";
import { getAllGlossaryTerms } from "@/lib/supabase/queries/lessons";

export const metadata = {
  title: "Glossary - Thuật ngữ đấu thầu | BidMentor",
  description:
    "Tra cứu thuật ngữ đấu thầu song ngữ Việt-Anh, giải thích thực tế, cảnh báo risk.",
};

export default async function GlossaryPage() {
  const terms = await getAllGlossaryTerms();

  return (
    <div className="max-w-4xl mx-auto px-4 py-10">
      <div className="space-y-2 mb-8">
        <h1 className="text-2xl font-medium text-gray-900">
          Glossary - Thuật ngữ đấu thầu
        </h1>
        <p className="text-gray-500 text-base leading-relaxed">
          {terms.length} thuật ngữ song ngữ Việt-Anh. Giải thích thực tế, không
          học thuật.
        </p>
      </div>
      <GlossaryClient terms={terms} />
    </div>
  );
}
