import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { GlossaryTerm, Lesson, LessonTier } from "@/lib/types";

export async function getLessonsGroupedByTier(): Promise<
  Record<LessonTier, Lesson[]>
> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("lessons")
    .select("*")
    .eq("is_published", true)
    .order("is_priority", { ascending: false })
    .order("created_at", { ascending: true });

  if (error) throw new Error(`getLessonsGroupedByTier: ${error.message}`);

  const grouped: Record<LessonTier, Lesson[]> = { 0: [], 1: [], 2: [], 3: [] };
  for (const lesson of (data ?? []) as Lesson[]) {
    grouped[lesson.tier].push(lesson);
  }
  return grouped;
}

export async function getLessonBySlug(slug: string): Promise<Lesson | null> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("lessons")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null;
    throw new Error(`getLessonBySlug: ${error.message}`);
  }
  return data as Lesson;
}

export async function getRelatedLessons(slugs: string[]): Promise<Lesson[]> {
  if (!slugs.length) return [];

  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("lessons")
    .select(
      "id, slug, title, tier, category, objective, is_priority, fatal_errors, is_published, view_count, tags, explanation, content_mdx, common_mistakes, related_slugs, quiz, title_en",
    )
    .in("slug", slugs)
    .eq("is_published", true);

  if (error) throw new Error(`getRelatedLessons: ${error.message}`);
  return (data ?? []) as Lesson[];
}

export async function incrementLessonViewCount(lessonId: string): Promise<void> {
  const supabase = await createServerSupabaseClient();
  await supabase.rpc("increment_lesson_view_count", { lesson_id: lessonId });
}

export async function getAllGlossaryTerms(): Promise<GlossaryTerm[]> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("glossary_terms")
    .select("*")
    .eq("is_published", true)
    .order("term_vn", { ascending: true });

  if (error) throw new Error(`getAllGlossaryTerms: ${error.message}`);
  return (data ?? []) as GlossaryTerm[];
}

export async function getGlossaryTermBySlug(
  slug: string,
): Promise<GlossaryTerm | null> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase
    .from("glossary_terms")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null;
    throw new Error(`getGlossaryTermBySlug: ${error.message}`);
  }
  return data as GlossaryTerm;
}

export async function getGlossaryTermMap(): Promise<Map<string, GlossaryTerm>> {
  const terms = await getAllGlossaryTerms();
  const map = new Map<string, GlossaryTerm>();
  for (const term of terms) {
    map.set(term.term_en.toLowerCase().trim(), term);
    map.set(term.term_vn.toLowerCase().trim(), term);
    map.set(term.slug, term);
  }
  return map;
}

export type LessonStatus = "not_started" | "in_progress" | "completed";

export async function getUserLessonProgress(
  userId: string,
  lessonId: string,
): Promise<LessonStatus> {
  const { createBrowserSupabaseClient } = await import("@/lib/supabase/client");
  const supabase = createBrowserSupabaseClient();
  const { data } = await supabase
    .from("user_lesson_progress")
    .select("status")
    .eq("user_id", userId)
    .eq("lesson_id", lessonId)
    .single();

  return (data?.status as LessonStatus) ?? "not_started";
}

export async function upsertLessonProgress(
  userId: string,
  lessonId: string,
  status: LessonStatus,
): Promise<void> {
  const { createBrowserSupabaseClient } = await import("@/lib/supabase/client");
  const supabase = createBrowserSupabaseClient();
  await supabase.from("user_lesson_progress").upsert(
    {
      user_id: userId,
      lesson_id: lessonId,
      status,
      ...(status === "completed"
        ? { completed_at: new Date().toISOString() }
        : {}),
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id,lesson_id" },
  );
}
