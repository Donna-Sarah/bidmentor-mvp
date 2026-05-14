"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_ITEMS = [
  { href: "/learn", icon: "ti-school", label: "Học đấu thầu" },
  { href: "/glossary", icon: "ti-book-2", label: "Glossary" },
  { href: "/analyze", icon: "ti-file-search", label: "Phân tích HSMT" },
  { href: "/compare", icon: "ti-scale", label: "So sánh năng lực" },
];

export function SidebarNav() {
  const pathname = usePathname();

  return (
    <nav className="flex-1 space-y-0.5">
      {NAV_ITEMS.map((item) => {
        const isActive =
          pathname === item.href || pathname.startsWith(`${item.href}/`);

        return (
          <Link
            key={item.href}
            href={item.href}
            className={`flex items-center gap-2.5 px-2 py-2 rounded-lg text-sm transition-colors group ${
              isActive
                ? "bg-gray-100 text-gray-900 font-medium"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
            }`}
          >
            <i
              className={`ti ${item.icon} text-base transition-colors ${
                isActive
                  ? "text-gray-700"
                  : "text-gray-400 group-hover:text-gray-600"
              }`}
              aria-hidden="true"
            />
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
