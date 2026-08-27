// SG Sujood — data Worker
//
// Serves the app's remote-config JSON (nisab, prayer spaces, terawih venues, prayer times) from
// the edge. GitHub stays the source of truth; this Worker just proxies the repo's raw files and
// caches them at Cloudflare's PoPs. Why not hit raw.githubusercontent.com directly from the app:
//   • GitHub rate-limits/serves raw on a best-effort basis and discourages CDN use of it,
//   • its cache is a fixed ~5 min with no control, no analytics, no custom domain,
//   • and it stops working the moment the repo is made private.
// Through this Worker the app gets a stable host, tuned cache headers, CORS (so a future web
// build works too), and continuity even if the repo goes private (make the fetch below
// authenticated with a token secret if you do).
//
// Deploy:  cd backend-data && npx wrangler deploy
// Test:    curl https://sgsujood-data.<subdomain>.workers.dev/nisab.json

const REPO = "blueyeagle/SG-Sujood";
const BRANCH = "main";

// Only these filenames are proxied — keeps this from being an open proxy for the whole repo.
const ALLOW = new Set([
  "nisab.json",
  "spaces.json",
  "terawih.json",
  "prayer_times.json",
]);

const EDGE_TTL = 300;      // seconds Cloudflare holds the object at the edge
const BROWSER_TTL = 600;   // seconds the app/browser may reuse its copy

function cors(res) {
  const h = new Headers(res.headers);
  h.set("access-control-allow-origin", "*");
  h.set("access-control-allow-methods", "GET, HEAD, OPTIONS");
  h.set("access-control-max-age", "86400");
  return new Response(res.body, { status: res.status, headers: h });
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return cors(new Response(null, { status: 204 }));
    if (request.method !== "GET" && request.method !== "HEAD") {
      return cors(json({ error: "method_not_allowed" }, 405));
    }

    const url = new URL(request.url);
    const name = url.pathname.replace(/^\/+/, "");

    // Health / discovery.
    if (name === "" || name === "health") {
      return cors(json({ ok: true, repo: REPO, branch: BRANCH, files: [...ALLOW] }));
    }
    if (!ALLOW.has(name)) return cors(json({ error: "not_found" }, 404));

    // Serve from the edge cache when possible.
    const cache = caches.default;
    const cacheKey = new Request(url.toString(), { method: "GET" });
    let res = await cache.match(cacheKey);
    if (res) return cors(res);

    const upstream = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/${name}`;
    const origin = await fetch(upstream, {
      cf: { cacheTtl: EDGE_TTL, cacheEverything: true },
      headers: { "user-agent": "sgsujood-data-worker" },
    });
    if (!origin.ok) {
      return cors(json({ error: "upstream_error", status: origin.status }, origin.status === 404 ? 404 : 502));
    }

    const body = await origin.arrayBuffer();
    res = new Response(body, {
      status: 200,
      headers: {
        "content-type": "application/json; charset=utf-8",
        "cache-control": `public, max-age=${BROWSER_TTL}`,
        "x-sgsujood-source": upstream,
      },
    });
    ctx.waitUntil(cache.put(cacheKey, res.clone()));
    return cors(res);
  },
};
