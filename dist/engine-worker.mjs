import { createRequire as __plotworkRequire } from 'node:module'; const require = __plotworkRequire(import.meta.url);
import {
  denyNetwork,
  runJob,
  useSelfhostIconArt
} from "./chunks/chunk-LRBXAQB4.mjs";
import "./chunks/chunk-42BVPR2M.mjs";

// src/engine-worker.ts
import { parentPort } from "node:worker_threads";
denyNetwork();
useSelfhostIconArt(import.meta.url);
parentPort?.on("message", (message) => {
  runJob(message.job).then(
    (value) => parentPort?.postMessage({ id: message.id, ok: true, value }),
    (error) => parentPort?.postMessage({ id: message.id, ok: false, error: error instanceof Error ? error.name : "Error" })
  );
});
