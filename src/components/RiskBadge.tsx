import type { RiskLevel } from "@/lib/types";

const RISK_BADGE_META: Record<
  RiskLevel,
  { bg: string; icon: string; label: string }
> = {
  fatal: { bg: "#DC2626", icon: "🔴", label: "FATAL" },
  high: { bg: "#EA580C", icon: "🟠", label: "HIGH RISK" },
  medium: { bg: "#CA8A04", icon: "🟡", label: "MEDIUM" },
  low: { bg: "#16A34A", icon: "🟢", label: "LOW" },
};

interface RiskBadgeProps {
  level: RiskLevel;
}

export function RiskBadge({ level }: RiskBadgeProps) {
  const meta = RISK_BADGE_META[level] ?? RISK_BADGE_META.medium;

  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-bold leading-none text-white"
      style={{ backgroundColor: meta.bg }}
    >
      <span aria-hidden="true">{meta.icon}</span>
      {meta.label}
    </span>
  );
}
