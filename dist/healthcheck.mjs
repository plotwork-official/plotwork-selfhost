import { createRequire as __plotworkRequire } from 'node:module'; const require = __plotworkRequire(import.meta.url);

// src/healthcheck.ts
import { request } from "node:http";
var port = Number(process.env["PLOTWORK_PORT"] ?? 3106);
var call = request({ host: "127.0.0.1", port, path: "/healthz", method: "GET", timeout: 3e3 }, (response) => {
  response.resume();
  process.exit(response.statusCode === 200 ? 0 : 1);
});
call.on("timeout", () => call.destroy());
call.on("error", () => process.exit(1));
call.end();
