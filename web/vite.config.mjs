import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

const webRoot = fileURLToPath(new URL(".", import.meta.url));
const webEntries = Object.freeze({
  app: resolve(webRoot, "index.html"),
  visualReference: resolve(webRoot, "visual-reference.html"),
});
const rollupOptions = Object.freeze({ input: webEntries });

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions,
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
  },
});
