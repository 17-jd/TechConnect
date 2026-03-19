"use client";
import { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [filter, setFilter] = useState<"all" | "customer" | "engineer">("all");
  const [search, setSearch] = useState("");

  useEffect(() => {
    return onSnapshot(
      query(collection(db, "users"), orderBy("createdAt", "desc")),
      (snap) => setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
  }, []);

  const filtered = users.filter(u => {
    const matchRole = filter === "all" || u.role === filter;
    const matchSearch = !search || u.name?.toLowerCase().includes(search.toLowerCase());
    return matchRole && matchSearch;
  });

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">Users</h1>

      <div className="flex gap-3 items-center">
        <input
          type="text"
          placeholder="Search by name..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:border-blue-400 w-56"
        />
        {(["all", "customer", "engineer"] as const).map(r => (
          <button
            key={r}
            onClick={() => setFilter(r)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              filter === r ? "bg-blue-600 text-white" : "bg-white text-gray-500 border border-gray-200"
            }`}
          >
            {r.charAt(0).toUpperCase() + r.slice(1)}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-xs text-gray-400 uppercase">
            <tr>
              {["Name", "Role", "Specialties", "Rating", "Joined", "Status"].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(u => (
              <tr key={u.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{u.name}</td>
                <td className="px-4 py-3">
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                    u.role === "engineer" ? "bg-purple-50 text-purple-700" : "bg-blue-50 text-blue-700"
                  }`}>{u.role}</span>
                </td>
                <td className="px-4 py-3 text-gray-400 text-xs">
                  {u.specialties?.slice(0, 2).join(", ") || "—"}
                  {u.specialties?.length > 2 && ` +${u.specialties.length - 2}`}
                </td>
                <td className="px-4 py-3">
                  {u.averageRating != null
                    ? <span className="text-yellow-600 font-medium">★ {u.averageRating.toFixed(1)} <span className="text-gray-400 font-normal">({u.reviewCount})</span></span>
                    : <span className="text-gray-300">—</span>}
                </td>
                <td className="px-4 py-3 text-gray-400 text-xs">
                  {u.createdAt?.toDate ? u.createdAt.toDate().toLocaleDateString() : "—"}
                </td>
                <td className="px-4 py-3">
                  {u.role === "engineer" && (
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      u.isOnline ? "bg-green-50 text-green-700" : "bg-gray-50 text-gray-400"
                    }`}>{u.isOnline ? "Online" : "Offline"}</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && <p className="text-center py-8 text-sm text-gray-400">No users found</p>}
      </div>
    </div>
  );
}
