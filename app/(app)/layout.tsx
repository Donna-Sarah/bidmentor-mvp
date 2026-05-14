import Link from "next/link";
import { type ReactNode } from "react";
import { SidebarNav } from "@/components/shared/SidebarNav";

const MOBILE_NAV = [
  { href: "/learn", icon: "ti-school", label: "Học đấu thầu" },
  { href: "/glossary", icon: "ti-book-2", label: "Glossary" },
  { href: "/analyze", icon: "ti-file-search", label: "Phân tích HSMT" },
  { href: "/compare", icon: "ti-scale", label: "So sánh năng lực" },
];

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50 flex">
      <aside className="hidden md:flex flex-col w-56 shrink-0 border-r border-gray-100 bg-white py-6 px-4">
        <Link href="/learn" className="flex items-center gap-2 mb-8 px-2">
          <span className="text-base font-medium text-gray-900">
            Bid<span className="text-blue-600">Mentor</span>
          </span>
        </Link>
        <SidebarNav />
        <div className="pt-4 border-t border-gray-100 space-y-0.5">
          <Link
            href="/settings"
            className="flex items-center gap-2.5 px-2 py-2 rounded-lg text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <i
              className="ti ti-settings text-base text-gray-400"
              aria-hidden="true"
            />
            Cài đặt
          </Link>
        </div>
      </aside>

      <div className="md:hidden fixed top-0 left-0 right-0 z-30 bg-white border-b border-gray-100 px-4 py-3 flex items-center justify-between">
        <Link href="/learn" className="text-base font-medium text-gray-900">
          Bid<span className="text-blue-600">Mentor</span>
        </Link>
        <div className="flex items-center gap-4">
          {MOBILE_NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              aria-label={item.label}
              className="text-gray-500 hover:text-gray-900 transition-colors"
            >
              <i className={`ti ${item.icon} text-xl`} aria-hidden="true" />
            </Link>
          ))}
        </div>
      </div>

      <main className="flex-1 min-w-0 md:pt-0 pt-14">{children}</main>
    </div>
  );
}
