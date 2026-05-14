import { NextRequest, NextResponse } from "next/server";
import { callClaude, parseAIJson } from "@/lib/ai/claude";
import {
  EXPLAIN_TERM_SYSTEM_PROMPT,
  buildExplainTermMessage,
} from "@/lib/ai/prompts/quick-scan";
import { getGlossaryTermBySlug } from "@/lib/supabase/queries/lessons";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { term, context, slug } = body as {
      term: string;
      context?: string;
      slug?: string;
    };

    if (!term || typeof term !== "string") {
      return NextResponse.json(
        { success: false, error: "term is required" },
        { status: 400 },
      );
    }

    if (slug) {
      const dbTerm = await getGlossaryTermBySlug(slug);
      if (dbTerm) {
        return NextResponse.json({ success: true, data: dbTerm, source: "db" });
      }
    }

    const result = await callClaude({
      system: EXPLAIN_TERM_SYSTEM_PROMPT,
      userMessage: buildExplainTermMessage({ term, context }),
      maxTokens: 800,
      feature: "explain_term",
    });

    const parsed = parseAIJson<{
      term_vn: string;
      term_en: string;
      eli5: string;
      practical_meaning: string;
      risk_note?: string;
      common_mistakes?: string[];
      related_terms?: string[];
      is_fatal_if_wrong: boolean;
    }>(result.content);

    return NextResponse.json({
      success: true,
      data: {
        term_vn: parsed.term_vn ?? term,
        term_en: parsed.term_en ?? term,
        eli5: parsed.eli5,
        practical_meaning: parsed.practical_meaning,
        risk_note: parsed.risk_note,
        common_mistakes: parsed.common_mistakes ?? [],
        is_fatal_if_wrong: parsed.is_fatal_if_wrong ?? false,
        slug: null,
      },
      source: "ai",
    });
  } catch (error) {
    console.error("[explain-term]", error);
    return NextResponse.json(
      { success: false, error: "Không thể giải thích thuật ngữ này." },
      { status: 500 },
    );
  }
}
