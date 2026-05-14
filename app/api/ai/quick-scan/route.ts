import { NextResponse } from "next/server";
import { z } from "zod";

import { callClaude, parseAIJson } from "@/lib/ai/claude";
import {
  QUICK_SCAN_SYSTEM_PROMPT,
  buildQuickScanMessage,
} from "@/lib/ai/prompts/quick-scan";

// ---------------------------------------------------------------------------
// HTTP body - what the client sends
// ---------------------------------------------------------------------------

const requestBodySchema = z.object({
  documentText: z
    .string("documentText must be a string")
    .trim()
    .min(1, "documentText cannot be empty")
    .max(
      600_000,
      "documentText is too long (max 600,000 characters). Truncate or split the HSMT.",
    ),
});

// ---------------------------------------------------------------------------
// AI JSON - matches `QUICK_SCAN_SYSTEM_PROMPT` (snake_case, flexible arrays)
// ---------------------------------------------------------------------------

const quickScanAiSchema = z.object({
  recommendation: z.enum(["GO", "NO_GO", "CONDITIONAL_GO"]),
  executive_summary: z.string(),
  fatal_errors: z
    .array(
      z
        .object({
          description: z.string(),
        })
        .passthrough(),
    )
    .optional()
    .default([]),
  high_risks: z
    .array(
      z
        .object({
          category: z.string().optional(),
          description: z.string(),
          mitigation: z.string().optional(),
        })
        .passthrough(),
    )
    .optional()
    .default([]),
  medium_risks: z
    .array(
      z
        .object({
          category: z.string().optional(),
          description: z.string(),
        })
        .passthrough(),
    )
    .optional()
    .default([]),
  timeline_assessment: z.string().optional(),
  estimated_workload_hours: z.union([z.number(), z.string()]).optional(),
});

// ---------------------------------------------------------------------------
// API response - stable contract for the frontend
// ---------------------------------------------------------------------------

const apiResponseSchema = z.object({
  recommendation: z.enum(["GO", "NO_GO", "CAUTION"]),
  summary: z.string(),
  fatalErrors: z.array(z.string()),
  risks: z.array(z.string()),
  workload: z.string(),
});

export type QuickScanApiResponse = z.infer<typeof apiResponseSchema>;

function mapAiJsonToApiResponse(
  ai: z.infer<typeof quickScanAiSchema>,
): QuickScanApiResponse {
  const recommendation =
    ai.recommendation === "CONDITIONAL_GO" ? "CAUTION" : ai.recommendation;

  const fatalErrors = ai.fatal_errors
    .map((e) => e.description.trim())
    .filter(Boolean);

  const risks: string[] = [];

  for (const r of ai.high_risks) {
    const label = r.category ? `[${r.category}] ` : "";
    const mit = r.mitigation?.trim() ? ` - Giảm thiểu: ${r.mitigation.trim()}` : "";
    const line = `${label}${r.description.trim()}${mit}`.trim();
    if (line) risks.push(line);
  }

  for (const r of ai.medium_risks) {
    const label = r.category ? `[${r.category}] ` : "";
    const line = `${label}${r.description.trim()}`.trim();
    if (line) risks.push(line);
  }

  const hoursPart =
    ai.estimated_workload_hours !== undefined &&
    ai.estimated_workload_hours !== null &&
    String(ai.estimated_workload_hours).trim() !== ""
      ? `Ước tính công sức chuẩn bị hồ sơ: khoảng ${String(ai.estimated_workload_hours).trim()} giờ (tham khảo AI, không thay thế judgment nội bộ).`
      : null;

  const timelinePart = ai.timeline_assessment?.trim() || null;

  const workload =
    [hoursPart, timelinePart].filter(Boolean).join(" ") ||
    "Không đủ dữ liệu trong văn bản để ước lượng chi tiết.";

  return {
    recommendation,
    summary: ai.executive_summary.trim() || "Không có tóm tắt.",
    fatalErrors,
    risks,
    workload,
  };
}

/**
 * Opening this URL in a browser sends GET - use POST for a real scan.
 */
export function GET(): NextResponse {
  return NextResponse.json({
    name: "BidMentor Quick Scan",
    hint: "Mở tab này bằng GET chỉ để kiểm tra route. Phân tích thật cần POST + JSON body.",
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: { documentText: "string - nội dung / đoạn HSMT cần quét nhanh" },
  });
}

/**
 * Quick Scan - phân tích nhanh HSMT (GO / NO-GO / CAUTION, fatal errors, risks, workload).
 * POST JSON: `{ "documentText": string }`
 */
export async function POST(request: Request): Promise<NextResponse> {
  let rawBody: unknown;

  try {
    rawBody = await request.json();
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON body. Send an object with `documentText` (string)." },
      { status: 400 },
    );
  }

  const parsedBody = requestBodySchema.safeParse(rawBody);
  if (!parsedBody.success) {
    return NextResponse.json(
      {
        error: "Validation failed",
        fieldErrors: parsedBody.error.flatten().fieldErrors,
        formErrors: parsedBody.error.flatten().formErrors,
      },
      { status: 400 },
    );
  }

  const { documentText } = parsedBody.data;

  try {
    const aiResult = await callClaude({
      system: QUICK_SCAN_SYSTEM_PROMPT,
      userMessage: buildQuickScanMessage({ hsmtText: documentText }),
      maxTokens: 8192,
      feature: "quick_scan",
    });

    let parsedJson: unknown;
    try {
      parsedJson = parseAIJson<unknown>(aiResult.content);
    } catch {
      return NextResponse.json(
        {
          error:
            "The model returned text that could not be parsed as JSON. Try again with a shorter excerpt or retry.",
        },
        { status: 502 },
      );
    }

    const parsedAi = quickScanAiSchema.safeParse(parsedJson);
    if (!parsedAi.success) {
      console.error(
        "[quick-scan] AI JSON validation failed:",
        parsedAi.error.flatten(),
      );
      return NextResponse.json(
        {
          error:
            "The model JSON did not match the expected Quick Scan shape. Please try again.",
        },
        { status: 502 },
      );
    }

    const payload = mapAiJsonToApiResponse(parsedAi.data);
    const validated = apiResponseSchema.safeParse(payload);
    if (!validated.success) {
      console.error("[quick-scan] Output mapping error:", validated.error);
      return NextResponse.json(
        { error: "Internal error while building the response." },
        { status: 500 },
      );
    }

    return NextResponse.json(validated.data satisfies QuickScanApiResponse);
  } catch (error) {
    console.error("[quick-scan] Unexpected error:", error);
    const message =
      error instanceof Error ? error.message : "Unexpected server error.";
    const isAiFailure = message.includes("AI call failed");
    return NextResponse.json(
      { error: isAiFailure ? message : "Something went wrong. Please try again." },
      { status: isAiFailure ? 503 : 500 },
    );
  }
}
