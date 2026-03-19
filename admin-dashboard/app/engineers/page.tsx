"use client";
import { useEffect, useState } from "react";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

export default function EngineersPage() {
  const [engineers, setEngineers] = useState<any[]>([]);
  const [jobs, setJobs] = useState<any[]>([]);

  useEffect(() => {
    const u1 = onSnapshot(
      query(collection(db, "users"), where("role", "==", "engineer")),
      (snap) => setEngineers(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
    const u2 = onSnapshot(collection(db, "serviceRequests"), (snap) =>
      setJobs(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
    return () => { u1(); u2(); };
  }, []);

  const jobsFor = (engineerId: string) => jobs.filter(j => j.engineerId === engineerId);
  const completedFor = (engineerId: string) => jobsFor(engineerId).filter(j => j.status === "completed");
  const earningsFor = (engineerId: string) => completedFor(engineerId).reduce((s, j) => s + (j.price || 0), 0);
  const activeJobFor = (engineerId: string) =>
    jobsFor(engineerId).find(j => ["accepted", "en_route", "arrived", "working"].includes(j.status));

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-gray-800">Engineers</h1>
      <div className="grid grid-cols-3 gap-3 mb-2">
        <div className="bg-white rounded-xl border border-gray-100 p-4 shadow-sm text-center">
          <div className="text-2xl font-bold text-gray-800">{engineers.length}</div>
          <div className="text-xs text-gray-400">Total</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-4 shadow-sm text-center">
          <div className="text-2xl font-bold text-green-600">{engineers.filter(e => e.isOnline).length}</div>
          <div className="text-xs text-gray-400">Online</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-4 shadow-sm text-center">
          <div className="text-2xl font-bold text-blue-600">
            {engineers.filter(e => activeJobFor(e.id)).length}
          </div>
          <div className="text-xs text-gray-400">On a Job</div>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-xs text-gray-400 uppercase">
            <tr>
              {["Name", "Status", "Current Job", "Completed", "Earnings", "Rating"].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {engineers.map(e => {
              const activeJob = activeJobFor(e.id);
              return (
                <tr key={e.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium">{e.name}</td>
                  <td className="px-4 py-3">
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      e.isOnline ? "bg-green-50 text-green-700" : "bg-gray-50 text-gray-400"
                    }`}>{e.isOnline ? "Online" : "Offline"}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 text-xs">
                    {activeJob ? `${activeJob.category} (${activeJob.status.replace("_", " ")})` : "—"}
                  </td>
                  <td className="px-4 py-3 text-gray-700">{completedFor(e.id).length}</td>
                  <td className="px-4 py-3 font-medium text-green-600">${earningsFor(e.id)}</td>
                  <td className="px-4 py-3">
                    {e.averageRating != null
                      ? <span className="text-yellow-600">★ {e.averageRating.toFixed(1)} <span className="text-gray-400">({e.reviewCount})</span></span>
                      : <span className="text-gray-300">—</span>}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {engineers.length === 0 && <p className="text-center py-8 text-sm text-gray-400">No engineers yet</p>}
      </div>
    </div>
  );
}
