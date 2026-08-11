// SG Sujood — prayer-space submission endpoint (Cloudflare Worker).
//
// Receives a JSON POST from the app and opens a GitHub issue in the repo using a token that
// lives ONLY here (never in the app). The repo's "space-submission" GitHub Action then
// appends the row to "Prayer Space for Review.xlsx". Anyone can submit — no GitHub account.
//
// Required Worker variables:
//   GITHUB_TOKEN  (secret)  — fine-grained PAT with Issues: Read and write on the repo
//   REPO          (var)     — e.g. "blueyeagle/SG-Sujood"
// Optional:
//   APP_KEY       (secret)  — if set, requests must send a matching "X-App-Key" header
//                             (light abuse deterrent; not strong security)

export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-App-Key",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    if (request.method !== "POST") return json({ error: "POST only" }, 405, cors);

    if (env.APP_KEY && request.headers.get("X-App-Key") !== env.APP_KEY) {
      return json({ error: "unauthorized" }, 401, cors);
    }

    let data;
    try { data = await request.json(); } catch { return json({ error: "invalid JSON" }, 400, cors); }

    const clip = (v, n) => (v == null ? "" : String(v)).slice(0, n).trim();
    const building = clip(data.building, 200);
    const floor = clip(data.floor, 400);
    const walk = clip(data.walk, 100);
    const type = clip(data.type, 40);
    if (!building) return json({ error: "building is required" }, 400, cors);

    const title = `[Space] ${building}`;
    const body = [
      `Building / mall: ${building}`,
      `Floor & landmark: ${floor}`,
      `Walk from nearest MRT exit: ${walk}`,
      `Type: ${type}`,
      "",
      "_Submitted from SG Sujood (app backend)._",
    ].join("\n");

    const res = await fetch(`https://api.github.com/repos/${env.REPO}/issues`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Accept": "application/vnd.github+json",
        "User-Agent": "waqtsg-submit",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ title, body }),
    });

    if (!res.ok) {
      const detail = (await res.text()).slice(0, 300);
      return json({ error: "github error", status: res.status, detail }, 502, cors);
    }
    const issue = await res.json();
    return json({ ok: true, issue: issue.number }, 200, cors);
  },
};

function json(obj, status, cors) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}
