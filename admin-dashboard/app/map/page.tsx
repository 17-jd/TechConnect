"use client";
import { useEffect, useState, useRef } from "react";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase-client";

export default function MapPage() {
  const [activeJobs, setActiveJobs] = useState<any[]>([]);
  const [selected, setSelected] = useState<any | null>(null);

  useEffect(() => {
    return onSnapshot(
      query(collection(db, "serviceRequests"),
        where("status", "in", ["accepted", "en_route", "arrived", "working"])),
      (snap) => setActiveJobs(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
  }, []);

  return (
    <div className="space-y-4 h-full">
      <h1 className="text-xl font-bold text-gray-800">Live Map</h1>

      <div className="flex gap-4" style={{ height: "calc(100vh - 140px)" }}>
        {/* Job list sidebar */}
        <div className="w-72 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-auto p-3 space-y-2 flex-shrink-0">
          <p className="text-xs font-semibold text-gray-400 uppercase px-1">
            {activeJobs.length} Active Jobs
          </p>
          {activeJobs.map(job => (
            <button
              key={job.id}
              onClick={() => setSelected(selected?.id === job.id ? null : job)}
              className={`w-full text-left p-3 rounded-xl border transition-colors ${
                selected?.id === job.id
                  ? "border-blue-300 bg-blue-50"
                  : "border-gray-100 hover:bg-gray-50"
              }`}
            >
              <div className="font-medium text-sm">{job.category}</div>
              <div className="text-xs text-gray-400 mt-0.5">
                {job.customerName} → {job.engineerName}
              </div>
              <div className="text-xs font-medium text-blue-600 mt-1">${job.price}</div>
            </button>
          ))}
          {activeJobs.length === 0 && (
            <p className="text-sm text-gray-400 text-center py-6">No active jobs right now</p>
          )}
        </div>

        {/* Map placeholder — replace with Google Maps or Mapbox embed */}
        <div className="flex-1 bg-white rounded-2xl border border-gray-100 shadow-sm relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-50 to-purple-50 flex flex-col items-center justify-center gap-3">
            <div className="text-4xl">🗺️</div>
            <p className="text-sm font-medium text-gray-600">Google Maps / Mapbox embed</p>
            <p className="text-xs text-gray-400 max-w-xs text-center">
              Add your <code className="bg-white px-1 rounded">NEXT_PUBLIC_GOOGLE_MAPS_KEY</code> to{" "}
              <code className="bg-white px-1 rounded">.env.local</code> and replace this div with a{" "}
              <code className="bg-white px-1 rounded">&lt;APIProvider&gt;</code> component from{" "}
              <code className="bg-white px-1 rounded">@vis.gl/react-google-maps</code>
            </p>

            {selected && (
              <div className="bg-white rounded-xl shadow p-4 mt-4 w-72 text-sm">
                <div className="font-semibold">{selected.category}</div>
                <div className="text-gray-400 text-xs mt-1">
                  Customer: {selected.customerName}<br />
                  Engineer: {selected.engineerName}<br />
                  Status: {selected.status.replace("_", " ")}<br />
                  Price: ${selected.price}
                </div>
                {selected.latitude && (
                  <div className="text-xs text-gray-400 mt-1">
                    📍 {selected.latitude.toFixed(4)}, {selected.longitude.toFixed(4)}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
