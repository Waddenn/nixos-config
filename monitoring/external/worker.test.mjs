import { test } from "node:test";
import assert from "node:assert/strict";
import { probe, transition, notify, run, TARGETS } from "./worker.mjs";

test("a login page must not pass a service health check", async () => {
  assert.equal((await probe(TARGETS[0], async () => new Response("login", { status: 302 }))).ok, false);
  assert.equal((await probe(TARGETS[0], async () => Response.json({ status: "OK" }))).ok, true);
  assert.equal((await probe(TARGETS[0], async () => Response.json({ status: "KO" }))).ok, false);
});
test("Codex requires the expected authentication redirect", async () => {
  const t = TARGETS.at(-1);
  assert.equal((await probe(t, async (_url, options) => {
    assert.equal(options.headers.Accept, "text/html");
    assert.equal(options.redirect, "manual");
    return new Response(null, { status: 302, headers: { location: "https://auth.hexaflare.net/?rd=x" } });
  })).ok, true);
  assert.equal((await probe(t, async () => new Response(null, { status: 302, headers: { location: "https://evil.example/" } }))).ok, false);
  assert.equal((await probe(t, async () => new Response(null, { status: 401, headers: { location: "https://auth.hexaflare.net/?rd=x" } }))).ok, true);
  assert.equal((await probe(t, async () => new Response(null, { status: 401 }))).ok, false);
});
test("Nextcloud maintenance and database upgrades are failures", async () => {
  const t = TARGETS.find(t => t.host === "nextcloud");
  assert.equal((await probe(t, async () => Response.json({ installed: true, maintenance: false, needsDbUpgrade: false }))).ok, true);
  assert.equal((await probe(t, async () => Response.json({ installed: true, maintenance: true, needsDbUpgrade: false }))).ok, false);
});
test("three consecutive failures alert once; recovery alerts once", () => {
  const failure = [{ name: "A", ok: false, reason: "HTTP 502" }];
  let s = transition({}, failure, "1");
  s = transition(s, failure, "2");
  assert.equal(s.pending.length, 0);
  s = transition(s, failure, "3");
  assert.equal(s.pending.length, 1);
  s.pending = [];
  s = transition(s, failure, "4");
  assert.equal(s.pending.length, 0);
  s = transition(s, [{ name: "A", ok: true, reason: null }], "5");
  assert.deepEqual(s.pending, [{ name: "A", down: false, reason: null }]);
  assert.equal(s.services.A.failures, 0);
});
test("an isolated failure resets after a successful probe", () => {
  const f = [{ name: "A", ok: false }], good = [{ name: "A", ok: true }];
  let s = transition({}, f, "1");
  s = transition(s, good, "2");
  s = transition(s, f, "3");
  assert.equal(s.services.A.failures, 1);
  assert.equal(s.pending.length, 0);
});
test("network errors are redacted", async () => {
  const r = await probe(TARGETS[0], async () => { throw new Error("sensitive response"); });
  assert.equal(r.reason, "DNS, TLS or network error");
  assert.ok(!JSON.stringify(r).includes("sensitive"));
});
test("alerts cannot mention Discord members", async () => {
  let payload;
  await notify("https://discord.com/api/webhooks/test/test", [{ name: "A", down: true, reason: "HTTP 502" }], async (_url, options) => {
    payload = JSON.parse(options.body); return new Response(null, { status: 204 });
  });
  assert.deepEqual(payload.allowed_mentions, { parse: [] });
});
test("a delivery test is clearly labelled, without a false incident", async () => {
  let payload;
  await notify("https://discord.com/api/webhooks/test/test", [{ name: "Sonde activée", test: true }], async (_url, options) => {
    payload = JSON.parse(options.body); return new Response(null, { status: 204 });
  });
  assert.ok(payload.content.includes("Test de livraison"));
  assert.ok(!payload.content.includes("Indisponible"));
});
test("failed deliveries retain pending alerts", async () => {
  let value = JSON.stringify({ pending: [{ name: "A", down: true }], services: {} });
  const env = { MONITOR_STATE: { get: async () => JSON.parse(value), put: async (_key, v) => { value = v; } }, DISCORD_WEBHOOK: "https://discord.com/api/webhooks/test/test" };
  await assert.rejects(run(env, async (_url, options) => options.method === "POST" ? new Response(null, { status: 500 }) : new Response(null, { status: 502 })), /delivery failed/);
  assert.equal(JSON.parse(value).pending.length, 1);
});
