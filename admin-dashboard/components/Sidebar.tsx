"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase-client";

const NAV = [
  { href: "/", label: "Overview", icon: "📊" },
  { href: "/users", label: "Users", icon: "👥" },
  { href: "/engineers", label: "Engineers", icon: "🔧" },
  { href: "/requests", label: "Requests", icon: "📋" },
  { href: "/map", label: "Live Map", icon: "🗺️" },
  { href: "/analytics", label: "Analytics", icon: "📈" },
  { href: "/notifications", label: "Notifications", icon: "🔔" },
];

export default function Sidebar() {
  const path = usePathname();
  return (
    <aside className="w-56 bg-white border-r border-gray-200 flex flex-col py-6">
      <div className="px-5 mb-8">
        <div className="text-lg font-bold" style={{ color: "var(--blue)" }}>TechConnect</div>
        <div className="text-xs text-gray-400 mt-0.5">Admin Dashboard</div>
      </div>
      <nav className="flex-1 px-3 space-y-1">
        {NAV.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
              path === item.href
                ? "bg-blue-50 text-blue-700"
                : "text-gray-600 hover:bg-gray-50"
            }`}
          >
            <span>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>
      <div className="px-4 pt-4 border-t border-gray-100">
        <button
          onClick={() => signOut(auth)}
          className="w-full text-left text-xs text-gray-400 hover:text-red-500 transition-colors"
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}
