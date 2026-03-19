"use client";
import { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

export default function NotificationsPage() {
  const [requests, setRequests] = useState<any[]>([]);

  useEffect(() => {
    return onSnapshot(
      query(collection(db, "serviceRequests"), orderBy("createdAt", "desc")),
      (snap) => setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
  }, []);

  // Only show requests that had at least one notification wave
  const notified = requests.filter(r => r.notificationWave != null || (r.notifiedEngineerIds?.length ?? 0) > 0);

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">Notification Wave Log</h1>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-xs text-gray-400 uppercase">
            <tr>
              {["Request", "Category", "Waves Sent", "Engineers Notified", "Accepted By", "Status"].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {notified.map(r => (
              <tr key={r.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-mono text-xs text-gray-400">{r.id.slice(0, 8)}…</td>
                <td className="px-4 py-3 font-medium">{r.category}</td>
                <td className="px-4 py-3 text-center">{(r.notificationWave ?? 0) + 1}</td>
                <td className="px-4 py-3 text-center">{r.notifiedEngineerIds?.length ?? 0}</td>
                <td className="px-4 py-3">{r.engineerName || <span className="text-gray-300">—</span>}</td>
                <td className="px-4 py-3">
                  <StatusBadge status={r.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {notified.length === 0 && (
          <p className="text-center py-8 text-sm text-gray-400">No notification waves sent yet</p>
        )}
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
