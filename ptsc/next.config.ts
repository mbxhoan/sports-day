import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  outputFileTracingRoot: process.cwd(),
  experimental: {
    serverActions: {
      // Gallery accepts multiple images; each image is validated at 10MB in uploadMedia.
      // Keep multipart overhead above the 10MB per-file storage limit.
      bodySizeLimit: "12mb",
    },
  },
  webpack(config) {
    // ponytail: Next 16.3 filesystem cache corrupts consecutive builds; re-enable after upstream fix.
    config.cache = false;
    return config;
  },
  images: {
    // Keep stable event assets at the edge instead of downloading originals per visitor.
    minimumCacheTTL: 31_536_000,
    remotePatterns: process.env.NEXT_PUBLIC_SUPABASE_URL
      ? [new URL("/storage/v1/object/public/event-media/**", process.env.NEXT_PUBLIC_SUPABASE_URL)]
      : [],
  },
};

export default nextConfig;
