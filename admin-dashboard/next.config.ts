import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Required for Cloudflare Pages via @cloudflare/next-on-pages
  experimental: {
    serverComponentsExternalPackages: ["firebase-admin"],
  },
};

export default nextConfig;
