import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { firm } from "./src/config/firm.config";

// PORT is only needed for the dev/preview server; defaults to 3000 for CI/build.
const port = Number(process.env.PORT || "3000");

// BASE_PATH is the Vite `base` setting; defaults to "/" for production builds.
const basePath = process.env.BASE_PATH || "/";

// Fills firm-specific values into index.html at build and dev time.
function firmHtml() {
  return {
    name: "firm-html",
    transformIndexHtml(html: string) {
      return html.replace(/__FIRM_NAME__/g, firm.name);
    },
  };
}

export default defineConfig({
  base: basePath,
  plugins: [
    react(),
    firmHtml(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname, "src"),
      "@assets": path.resolve(import.meta.dirname, "..", "..", "attached_assets"),
    },
    dedupe: ["react", "react-dom"],
  },
  root: path.resolve(import.meta.dirname),
  build: {
    outDir: path.resolve(import.meta.dirname, "dist"),
    emptyOutDir: true,
    minify: false,
  },
  server: {
    port,
    strictPort: true,
    host: "0.0.0.0",
    allowedHosts: true,
    fs: {
      strict: true,
    },
  },
  preview: {
    port,
    host: "0.0.0.0",
    allowedHosts: true,
  },
});
