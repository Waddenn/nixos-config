// Runs outside the homelab. No credentials are sent to the monitored services.
export const TARGETS = [
  { name: "Authelia", host: "auth", path: "/api/health", check: b => b.status === "OK" },
  { name: "Vaultwarden", host: "bitwarden", path: "/alive", check: b => typeof b === "string" },
  { name: "Immich", host: "immich", path: "/api/server/ping", check: b => b.res === "pong" },
  { name: "Jellyseerr", host: "jellyseerr", path: "/api/v1/status", check: b => typeof b.version === "string" },
  { name: "Home Assistant", host: "homeassistant", path: "/manifest.json", check: b => typeof b.name === "string" },
  { name: "Nextcloud", host: "nextcloud", path: "/status.php", check: b => b.installed === true && b.maintenance === false && b.needsDbUpgrade === false },
  // This checks the public authentication gate, not the authenticated Codex backend.
  { name: "Codex ingress", host: "codex", path: "/", redirect: true },
];

export async function probe(target, fetcher = fetch) {
  const start = Date.now();
  try {
    const response = await fetcher(`https://${target.host}.hexaflare.net${target.path}`, {
      method: "GET", redirect: "manual", signal: AbortSignal.timeout(15000),
      headers: { "User-Agent": "Hexaflare-External-Monitor/1.0", "Cache-Control": "no-cache",
        "Accept": target.redirect ? "text/html" : "application/json" },
      cf: { cacheTtl: 0, cacheEverything: false },
    });
    const status = response.status;
    let ok = false;
    if (target.redirect) {
      const location = new URL(response.headers.get("location") || "/", `https://${target.host}.hexaflare.net`);
      // Authelia may return 401 with its login Location for non-browser clients.
      ok = [302, 303, 307, 308, 401].includes(status) && location.origin === "https://auth.hexaflare.net";
      await response.body?.cancel();
    } else if (status === 200) {
      const body = await response.json();
      ok = target.check(body);
    } else {
      await response.body?.cancel();
    }
    return { name: target.name, ok, status, ms: Date.now() - start,
      reason: ok ? null : status === 200 ? "Unexpected application response" : `HTTP ${status}` };
  } catch (error) {
    // Do not store response bodies, cookies, credentials, or raw exception messages.
    return { name: target.name, ok: false, status: null, ms: Date.now() - start,
      reason: ["TimeoutError", "AbortError"].includes(error.name) ? "Timeout" : "DNS, TLS or network error" };
  }
}

export function transition(previous = {}, results, checkedAt) {
  const services = {}, changes = [];
  for (const result of results) {
    const old = previous.services?.[result.name] || { failures: 0, down: false };
    const failures = result.ok ? 0 : old.failures + 1;
    const down = result.ok ? false : old.down || failures >= 3;
    services[result.name] = { ...result, failures, down };
    if (down !== old.down) changes.push({ name: result.name, down, reason: result.reason });
  }
  return { checkedAt, services, pending: [...(previous.pending || []), ...changes] };
}

export async function notify(webhook, changes, fetcher = fetch) {
  if (!changes.length) return;
  const url = new URL(webhook);
  if (url.protocol !== "https:" || url.hostname !== "discord.com" || !url.pathname.startsWith("/api/webhooks/")) {
    throw new Error("Invalid Discord webhook configuration");
  }
  const response = await fetcher(url, {
    method: "POST", signal: AbortSignal.timeout(15000),
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ allowed_mentions: { parse: [] }, content:
      "Surveillance extérieure Hexaflare\n" + changes.map(c => c.test ?
        `🔎 Test de livraison : ${c.name}` :
        `${c.down ? "🔴 Indisponible" : "🟢 Rétabli"} : ${c.name}${c.reason ? ` (${c.reason})` : ""}`).join("\n") }),
  });
  await response.body?.cancel();
  if (!response.ok) throw new Error(`Discord delivery failed: HTTP ${response.status}`);
}

export async function run(env, fetcher = fetch) {
  if (!env.MONITOR_STATE) throw new Error("MONITOR_STATE binding required");
  const previous = await env.MONITOR_STATE.get("state", "json") || {};
  const results = await Promise.all(TARGETS.map(target => probe(target, fetcher)));
  const state = transition(previous, results, new Date().toISOString());
  // Persist pending alerts first, so delivery failures can be retried on the next run.
  await env.MONITOR_STATE.put("state", JSON.stringify(state));
  if (state.pending.length && env.DISCORD_WEBHOOK) {
    await notify(env.DISCORD_WEBHOOK, state.pending, fetcher);
    console.log(JSON.stringify({ discordDelivered: state.pending.length }));
    state.pending = [];
    // KV permits only one write per second to a given key.
    await new Promise(resolve => setTimeout(resolve, 1100));
    await env.MONITOR_STATE.put("state", JSON.stringify(state));
  }
  console.log(JSON.stringify({ checkedAt: state.checkedAt, results }));
  return state;
}

export default {
  // No public trigger or public incident dashboard.
  fetch() { return new Response("Not found", { status: 404 }); },
  async scheduled(_event, env) { await run(env); },
};
