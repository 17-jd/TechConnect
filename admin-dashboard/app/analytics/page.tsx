"use client";
import { useEffect, useState } from "react";
import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase-client";
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from "recharts";

export default function AnalyticsPage() {
  const [jobsByDay, setJobsByDay] = useState<any[]>([]);
  const [revenueByDay, setRevenueByDay] = useState<any[]>([]);
  const [byCategory, setByCategory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snap = await getDocs(
      query(collection(db, "serviceRequests"), where("createdAt", ">=", thirtyDaysAgo))
    );
    const docs = snap.docs.map(d => d.data());

    // Group by day
    const dayMap: Record<string, { jobs: number; revenue: number }> = {};
    const catMap: Record<string, number> = {};

    docs.forEach(d => {
      const date = d.createdAt?.toDate ? d.createdAt.toDate() : new Date();
      const dayKey = date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      if (!dayMap[dayKey]) dayMap[dayKey] = { jobs: 0, revenue: 0 };
      dayMap[dayKey].jobs += 1;
      if (d.status === "completed") dayMap[dayKey].revenue += d.price || 0;

      if (d.category) catMap[d.category] = (catMap[d.category] || 0) + 1;
    });

    const days = Object.entries(dayMap)
      .map(([date, v]) => ({ date, ...v }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    setJobsByDay(days);
    setRevenueByDay(days);
    setByCategory(Object.entries(catMap).map(([name, count]) => ({ name, count })).sort((a, b) => b.count - a.count));
    setLoading(false);
  }

  if (loading) return <div className="text-sm text-gray-400 pt-8">Loading analytics...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-800">Analytics</h1>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Jobs per Day (last 30 days)</h2>
        <ResponsiveContainer width="100%" height={220}>
          <LineChart data={jobsByDay}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip />
            <Line type="monotone" dataKey="jobs" stroke="#1a73e8" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Revenue per Day ($)</h2>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={revenueByDay}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip formatter={(v) => `$${v}`} />
            <Bar dataKey="revenue" fill="#10b981" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Jobs by Category</h2>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={byCategory} layout="vertical">
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis type="number" tick={{ fontSize: 11 }} />
            <YAxis dataKey="name" type="category" tick={{ fontSize: 11 }} width={110} />
            <Tooltip />
            <Bar dataKey="count" fill="#6c3ce1" radius={[0, 4, 4, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
