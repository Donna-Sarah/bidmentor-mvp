import Anthropic, { APIError } from "@anthropic-ai/sdk";

// ============================================================
// BidMentor - Claude API Client
// All AI calls go through here. Never call API directly in components.
// ============================================================

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

/** Default: Sonnet 4.6 (Sonnet 4 `claude-sonnet-4-20250514` is retired / 404 on API). Override with ANTHROPIC_MODEL. */
export const CLAUDE_MODEL =
  process.env.ANTHROPIC_MODEL?.trim() || "claude-sonnet-4-6";

export interface AICallOptions {
  system: string;
  userMessage: string;
  maxTokens?: number;
  feature: string; // for logging: 'quick_scan' | 'explain_term' | 'deep_analysis'
}

export interface AIResult {
  content: string;
  inputTokens: number;
  outputTokens: number;
  model: string;
}

// Standard (non-streaming) call
export async function callClaude(options: AICallOptions): Promise<AIResult> {
  const { system, userMessage, maxTokens = 2000, feature } = options;

  try {
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content: userMessage }],
    });

    const content = response.content
      .filter((block) => block.type === "text")
      .map((block) => (block as { type: "text"; text: string }).text)
      .join("");

    const result: AIResult = {
      content,
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
      model: response.model,
    };

    // Log usage (fire and forget - don't block)
    logAIUsage(feature, result).catch(console.error);

    return result;
  } catch (error) {
    console.error(`[BidMentor AI] Error in ${feature}:`, error);
    if (error instanceof APIError) {
      throw new Error(
        `AI call failed for ${feature} (${error.status}): ${error.message}`,
      );
    }
    throw new Error(`AI call failed for ${feature}. Please try again.`);
  }
}

// Streaming call - returns a ReadableStream for real-time UI
export async function callClaudeStream(
  options: AICallOptions
): Promise<ReadableStream<string>> {
  const { system, userMessage, maxTokens = 2000 } = options;

  let stream: AsyncIterable<unknown>;
  try {
    stream = await anthropic.messages.stream({
      model: CLAUDE_MODEL,
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content: userMessage }],
    });
  } catch (error) {
    console.error(`[BidMentor AI] Stream error:`, error);
    if (error instanceof APIError) {
      throw new Error(`AI stream failed (${error.status}): ${error.message}`);
    }
    throw new Error("AI stream failed. Please try again.");
  }

  return new ReadableStream({
    async start(controller) {
      for await (const rawChunk of stream) {
        const chunk = rawChunk as {
          type?: string;
          delta?: { type?: string; text?: string };
        };
        if (
          chunk.type === "content_block_delta" &&
          chunk.delta?.type === "text_delta" &&
          typeof chunk.delta.text === "string"
        ) {
          controller.enqueue(chunk.delta.text);
        }
      }
      controller.close();
    },
  });
}

// Parse structured JSON from AI response (with fence stripping)
export function parseAIJson<T>(rawContent: string): T {
  const cleaned = rawContent
    .replace(/```json\n?/g, "")
    .replace(/```\n?/g, "")
    .trim();

  try {
    return JSON.parse(cleaned) as T;
  } catch {
    console.error("[BidMentor AI] Failed to parse JSON:", cleaned);
    throw new Error("AI response could not be parsed. Please try again.");
  }
}

// Usage logging (sends to Supabase - called fire-and-forget)
async function logAIUsage(feature: string, result: AIResult): Promise<void> {
  // Dynamically import to avoid circular deps
  const { createClient } = await import("@/lib/supabase/server");
  const supabase = await createClient();

  await supabase.from("ai_usage_log").insert({
    feature,
    ai_model: result.model,
    input_tokens: result.inputTokens,
    output_tokens: result.outputTokens,
    // Rough cost estimate for Claude Sonnet
    cost_usd:
      (result.inputTokens * 0.000003 + result.outputTokens * 0.000015),
  });
}
