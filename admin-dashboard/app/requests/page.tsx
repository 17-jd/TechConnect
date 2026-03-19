"use client";
import { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

const STATUS_OPTIONS = ["all", "open", "accepted", "en_route", "arrived", "working", "completed", "cancelled"];

export default function RequestsPage() {
  const [requests, setRequests] = useState<any[]>([]);
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    return onSnapshot(
      query(collection(db, "serviceRequests"), orderBy("createdAt", "desc")),
      (snap) => setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
  }, []);

  const filtered = filter === "all" ? requests : requests.filter(r => r.status === filter);

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">Requests</h1>

      <div className="flex gap-2 flex-wrap">
        {STATUS_OPTIONS.map(s => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
              filter === s ? "bg-blue-600 text-white" : "bg-white text-gray-500 border border-gray-200"
            }`}
          >
            {s === "en_route" ? "En Route" : s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-xs text-gray-400 uppercase">
            <tr>
              {["Category", "Customer", "Engineer", "Price", "Status", "Date"].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(r => (
              <tr key={r.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{r.category}</td>
                <td className="px-4 py-3 text-gray-600">{r.customerName}</td>
                <td className="px-4 py-3 text-gray-600">{r.engineerName || <span className="text-gray-300">—</span>}</td>
                <td className="px-4 py-3 font-medium text-blue-600">${r.price}</td>
                <td className="px-4 py-3">
                  <StatusBadge status={r.status} />
                </td>
                <td className="px-4 py-3 text-gray-400 text-xs">
                  {r.createdAt?.toDate ? r.createdAt.toDate().toLocaleString() : "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && <p className="text-center py-8 text-sm text-gray-400">No requests</p>}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    open: "bg-yellow-50 text-yellow-700", accepted: "bg-blue-50 text-blue-700",
    en_route: "bg-blue-50 text-blue-600", arrived: "bg-purple-50 text-purple-700",
    working: "bg-orange-50 text-orange-700", completed: "bg-green-50 text-green-700",
    cancelled: "bg-gray-50 text-gray-400",
  };
  const label = status === "en_route" ? "En Route" : status.charAt(0).toUpperCase() + status.slice(1);
  return <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${map[status] || ""}`}>{label}</span>;
}
