"use client";
import { useEffect, useState } from "react";
import { collection, onSnapshot, query, where, orderBy, limit, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

interface StatCard { label: string; value: string | number; sub?: string; color?: string }

function Card({ label, value, sub, color = "#1a73e8" }: StatCard) {
  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
      <p className="text-xs text-gray-400 font-medium uppercase tracking-wide">{label}</p>
      <p className="text-3xl font-bold mt-1" style={{ color }}>{value}</p>
      {sub && <p className="text-xs text-gray-400 mt-1">{sub}</p>}
    </div>
  );
}

export default function OverviewPage() {
  const [customers, setCustomers] = useState(0);
  const [engineers, setEngineers] = useState(0);
  const [onlineEngineers, setOnlineEngineers] = useState(0);
  const [activeJobs, setActiveJobs] = useState(0);
  const [openRequests, setOpenRequests] = useState(0);
  const [revenueToday, setRevenueToday] = useState(0);
  const [revenueWeek, setRevenueWeek] = useState(0);
  const [feed, setFeed] = useState<any[]>([]);

  useEffect(() => {
    const unsubs: (() => void)[] = [];

    // Users
    unsubs.push(onSnapshot(collection(db, "users"), (snap) => {
      const docs = snap.docs.map(d => d.data());
      setCustomers(docs.filter(d => d.role === "customer").length);
      setEngineers(docs.filter(d => d.role === "engineer").length);
      setOnlineEngineers(docs.filter(d => d.role === "engineer" && d.isOnline).length);
    }));

    // Active / open jobs
    unsubs.push(onSnapshot(
      query(collection(db, "serviceRequests"), where("status", "in", ["accepted", "en_route", "arrived", "working"])),
      (snap) => setActiveJobs(snap.size)
    ));
    unsubs.push(onSnapshot(
      query(collection(db, "serviceRequests"), where("status", "==", "open")),
      (snap) => setOpenRequests(snap.size)
    ));

    // Revenue
    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const weekStart = new Date(); weekStart.setDate(weekStart.getDate() - 7);

    unsubs.push(onSnapshot(
      query(collection(db, "serviceRequests"), where("status", "==", "completed")),
      (snap) => {
        const docs = snap.docs.map(d => d.data());
        const completedAt = (d: any): Date => d.completedAt?.toDate ? d.completedAt.toDate() : new Date(0);
        setRevenueToday(docs.filter(d => completedAt(d) >= todayStart).reduce((s, d) => s + (d.price || 0), 0));
        setRevenueWeek(docs.filter(d => completedAt(d) >= weekStart).reduce((s, d) => s + (d.price || 0), 0));
      }
    ));

    // Live feed — last 10 events
    unsubs.push(onSnapshot(
      query(collection(db, "serviceRequests"), orderBy("createdAt", "desc"), limit(10)),
      (snap) => setFeed(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    ));

    return () => unsubs.forEach(u => u());
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-bold text-gray-800">Overview</h1>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card label="Customers" value={customers} />
        <Card label="Engineers" value={engineers} />
        <Card label="Online Now" value={onlineEngineers} sub="engineers" color="#10b981" />
        <Card label="Active Jobs" value={activeJobs} color="#f59e0b" />
        <Card label="Open Requests" value={openRequests} color="#6c3ce1" />
        <Card label="Revenue Today" value={`$${revenueToday}`} color="#10b981" />
        <Card label="Revenue This Week" value={`$${revenueWeek}`} color="#10b981" />
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Live Feed</h2>
        <div className="space-y-2">
          {feed.map((item) => (
            <div key={item.id} className="flex items-center justify-between text-sm py-2 border-b border-gray-50 last:border-0">
              <div className="flex items-center gap-3">
                <StatusDot status={item.status} />
                <span className="font-medium">{item.category}</span>
                <span className="text-gray-400 text-xs">by {item.customerName}</span>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-gray-600">${item.price}</span>
                <StatusChip status={item.status} />
              </div>
            </div>
          ))}
          {feed.length === 0 && <p className="text-sm text-gray-400">No recent activity</p>}
        </div>
      </div>
    </div>
  );
}

function StatusDot({ status }: { status: string }) {
  const colors: Record<string, string> = {
    open: "bg-yellow-400", accepted: "bg-blue-400", en_route: "bg-blue-500",
    arrived: "bg-purple-500", working: "bg-orange-400", completed: "bg-green-500", cancelled: "bg-gray-300",
  };
  return <span className={`w-2 h-2 rounded-full ${colors[status] || "bg-gray-300"}`} />;
}

function StatusChip({ status }: { status: string }) {
  const labels: Record<string, string> = {
    open: "Open", accepted: "Accepted", en_route: "En Route",
    arrived: "Arrived", working: "Working", completed: "Done", cancelled: "Cancelled",
  };
  const colors: Record<string, string> = {
    open: "bg-yellow-50 text-yellow-700", accepted: "bg-blue-50 text-blue-700",
    en_route: "bg-blue-50 text-blue-700", arrived: "bg-purple-50 text-purple-700",
    working: "bg-orange-50 text-orange-700", completed: "bg-green-50 text-green-700",
    cancelled: "bg-gray-50 text-gray-500",
  };
  return (
    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${colors[status] || "bg-gray-50 text-gray-500"}`}>
      {labels[status] || status}
    </span>
  );
}
