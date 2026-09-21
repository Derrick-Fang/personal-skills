---
name: inference-market-radar
description: Daily radar for AI inference markets. Track model demand, new models, important inference-serving optimizations, and major competitor moves. Focus on changes that should affect what models we deploy, benchmark, or optimize. Use when the user asks for an inference market report, daily radar, model demand trends, OpenRouter usage shifts, SGLang/vLLM/TensorRT-LLM optimization roundup, or competitor moves from Together/Fireworks/Baseten/Parasail/DeepInfra/Groq/Cerebras/SiliconFlow, and optimization-layer vendors such as Wafer that publish speedups over SGLang/vLLM. Verifies every claim against official vendor sites, model cards and official X accounts before reporting it.
allowed-tools: WebSearch, WebFetch, Bash, Read, Write, Glob, Grep, Agent
---

# Inference Market Radar

Act as the daily technical intelligence analyst for an AI inference provider.

Do not produce general AI news.

Your job is to answer:

> What changed today that should affect which models we serve, benchmark, or optimize?

Focus on four areas:

1. Model demand
2. New models
3. Serving optimizations
4. Major competitor moves

Default window: **last 24–48 hours**.

If nothing meaningful changed, say so.

---

# 1. Model Demand

Use OpenRouter and other reliable usage signals.

Find:

- most-used models
- fastest-growing models
- declining models
- newly trending models
- coding / agent / reasoning workload shifts
- major token-volume changes

Focus on **change**, not static rankings.

Good:

> Model X moved from #10 to #3 and token volume doubled this week.

Bad:

> Model X is currently #3.

When possible compare:

- today
- yesterday
- 7-day trend

Do not confuse token volume with user count.

---

# 2. New Models

Track important new model releases from:

- Hugging Face
- official model repositories
- official announcements
- OpenRouter adoption

Only include models likely to matter for inference demand.

For each model report:

**Model:**  
**Released:**  
**Architecture:** dense / MoE / unusual attention  
**Size / active parameters:**  
**Context:**  
**Open weights:** yes/no  
**Serving support:** SGLang / vLLM  
**Current demand signal:**  
**Inference implications:**  

Then give:

**Priority: P0 / P1 / P2**

- P0: benchmark now
- P1: watch
- P2: ignore for now

---

# 3. Serving Optimization Radar

Combine important developments from:

- SGLang
- vLLM
- NVIDIA / TensorRT-LLM
- FlashInfer when relevant

Focus on:

- new model support
- MoE
- expert parallelism
- attention kernels
- MLA / sparse attention
- speculative decoding
- KV cache
- prefix caching
- KV transfer
- PD disaggregation
- scheduling
- continuous batching
- chunked prefill
- quantization
- FP8
- NVFP4
- MXFP4
- CUDA Graph
- NCCL / communication
- multi-node serving
- Blackwell / RTX 5090 / B200 / B300
- throughput / TTFT / TPOT improvements

Ignore documentation changes and minor bug fixes.

## How to enumerate — search the window, do not paginate the repo

Listing every merged PR in each repo costs hundreds of fetches to surface a handful of items. Query the window directly:

```
curl -s "https://api.github.com/search/issues?q=repo:sgl-project/sglang+is:pr+is:merged+merged:>=YYYY-MM-DD&sort=created&per_page=50"
```

Narrow further with a term when you are chasing one model or subsystem (`+DeepSeek+in:title`, `+quantization+in:title`). Then open only the PRs that survive triage and read those bodies in full:

```
curl -s "https://api.github.com/repos/<owner>/<repo>/pulls/<num>"   # .title, .merged_at, .body
```

Check `releases?per_page=3` per repo as well — a release may fall just outside the window while its contents are exactly what changed.

For every important PR or release:

### Project — PR / Release

**What changed:**  
Explain the optimization simply.

**Why it matters:**  
What bottleneck does it improve?

**Benchmark:**  
Include numbers and setup when available.

Important context:

- GPU
- model
- quantization
- TP / EP
- concurrency
- input/output lengths
- baseline

**Applicable to:**  
Models / GPUs / workloads.

**Action:** Ignore / Watch / Reproduce / Port

Do not report performance claims without understanding the benchmark conditions.

---

# 4. Competitor Radar

Only track major inference providers and only report meaningful moves.

Examples:

- Together AI
- Fireworks AI
- DeepInfra
- SiliconFlow
- Groq
- Cerebras
- major OpenRouter providers

## Watchlist — check these directly, do not wait for news to surface them

Each run, sweep the blogs and official X accounts below. These are **information sources**, not just threat targets: competitors publish benchmark methodology, kernel details and pricing that no aggregator reproduces.

### Order of work: detect from OpenRouter first, then confirm on the vendor site

Crawling ~25 vendor blogs is the slowest part of this skill and the thinnest in signal. Do it second, not first.

**Step 1 — detect.** One pass over the OpenRouter APIs tells you, as measured data, which competitor added which model, at what price, at what quantization, and at what actual speed:

```
# every provider OpenRouter routes to
curl -s "https://openrouter.ai/api/v1/providers"

# per-model provider list: pricing, context, quantization, uptime
curl -s "https://openrouter.ai/api/v1/models/<author>/<slug>/endpoints"

# per-model provider list WITH measured p50 throughput and p50 latency
curl -s "https://openrouter.ai/api/frontend/v1/stats/endpoint?permaslug=<permaslug>"
```

Diff that against the previous run. A competitor that launched a model, cut a price, changed quantization, or lost throughput shows up here before it shows up on a blog — and shows up as a number rather than a paragraph.

**Step 2 — confirm.** Open the vendor blog only for the competitors the diff flagged, plus the optimization-layer vendors in section 4C, whose claims never appear in any API. Everything else gets "nothing material" without a fetch.

**Never invert the trust order.** A vendor catalog page or sitemap that omits a model is not evidence the vendor is not serving it — a live OpenRouter endpoint with measured throughput outranks the vendor's own marketing surface. Two cases seen in production: Parasail's catalog did not list DeepSeek-V4.1-Flash while Parasail was serving it at the best measured TTFT of any provider; SiliconFlow's own pricing page carried no V4.1 SKU while its OpenRouter endpoint ran at 100% uptime.

**Measured throughput is also the check on any speed claim.** An optimization vendor's "N× faster" is testable in one call: compare its p50 throughput against the other providers of the same model. A vendor that leads on the one model it tuned and sits mid-pack on the rest has a tuning result, not an engine advantage — report it that way.

### A. Serving competitors (token sellers)

| Competitor | Primary source | Note |
|---|---|---|
| Together AI | together.ai/blog | price leader at scale; batch / reserved tiers |
| Fireworks AI | fireworks.ai/blog | publishes engine internals |
| Baseten | baseten.co/blog | strong model-launch writeups; often first out on new models |
| DeepInfra | deepinfra.com | open-weights price floor |
| Novita AI | novita.ai/blog | |
| **Parasail** | parasail.io/blog | **watch closely** — partners with both Wafer and d-Matrix; first to put new optimization and non-NVIDIA silicon into production |
| Nebius AI Studio | nebius.com | EU data residency |
| Hyperbolic / Chutes / Featherless / CrofAI | OpenRouter provider pages | long-tail price pressure |

### B. Hardware-differentiated

| Competitor | Hardware | Note |
|---|---|---|
| Groq | LPU | latency leader claims |
| Cerebras | Wafer-Scale Engine | fastest tok/s on small–mid open models |
| SambaNova | SN-series | SoftBank, JPMorgan deployments |
| d-Matrix | Corsair (DIMC) | in production; deployed via Parasail |
| Positron AI | Atlas | shipping |
| Etched | Sohu (transformer-hardwired) | first-pass silicon, validating |
| Tenstorrent | | |

### C. Optimization-layer competitors — highest signal for us

A newer category: they do not sell tokens, they sell the optimization. **Their published numbers are direct head-to-head claims against SGLang and vLLM — i.e. against our own stack.** Read every one.

| Competitor | Primary source | Note |
|---|---|---|
| **Wafer** | wafer.ai/blog · wafer.ai/technology · wafer.ai/cases · `@wafer_ai` | Autonomous performance-engineering agents: profiles a production workload on its accelerator, then rewrites the serving stack — kernels, batching, scheduling, memory layout. **Claims up to 2.8× over baseline SGLang / vLLM at identical weights and outputs** `[vendor]`. YC S25 (formerly Herdora), $40M Series A Sept 2026 (~$200M+ val), AMD Ventures among investors. Sources disagree on whether it serves on non-NVIDIA silicon itself or only optimizes GPU stacks — resolve before citing. |

When such a vendor publishes a speedup over SGLang/vLLM, do not report the multiplier alone. Extract:

- baseline **version** of SGLang/vLLM (an old baseline inflates everything)
- GPU, quantization, TP/EP
- batch size / concurrency and input/output lengths
- whether outputs are bit-identical or merely "quality preserved"
- end-to-end throughput vs a single kernel

A multiplier without that setup is marketing, and must be labeled `[vendor]`.

### D. China

| Competitor | Primary source | Note |
|---|---|---|
| SiliconFlow 硅基流动 | siliconflow.cn/news | largest independent token supplier in China by throughput (Frost & Sullivan 2025) `[3P]`; **filed for HKEX main board June 2026 — the prospectus carries audited token volume and unit economics, rare hard data** |
| PPIO 派欧云 | ppio.cn | |
| Infinigence 无问芯穹 | infini-ai.com | domestic-silicon heterogeneous serving |
| Volcengine Ark 火山引擎 | volcengine.com | |
| Alibaba Bailian / Qwen API | bailian.console.aliyun.com | |
| Zhipu | bigmodel.cn | |

### E. Measured third-party vantage points

- **OpenRouter provider pages** (`openrouter.ai/provider/<name>`) — per-provider latency, throughput and uptime. This is measured data, not provider claims. Use it to check a competitor's speed claim against reality.
- Artificial Analysis
- Hugging Face Inference Providers

## Extra triggers worth reporting

Beyond the list below, these are reportable for this watchlist:

- **Partnership announcements** between an optimization-layer or chip vendor and a serving provider (e.g. Wafer×Parasail, d-Matrix×Parasail) — these reveal which technology reaches production first, usually months before benchmarks appear.
- **A published head-to-head against SGLang or vLLM** — always reportable, regardless of the multiplier claimed.
- **IPO filings / prospectuses** — audited volume and margin data that is otherwise unobtainable.
- **Chip-vendor funding rounds with a strategic investor** (e.g. AMD Ventures) — signals which silicon gets a serving foothold next.

Ignore routine marketing.

Only report things such as:

- major new model support
- significant price cut
- major speed improvement
- unusual latency improvement
- important new hardware deployment
- new quantization
- major capacity expansion
- obvious competitive advantage

For each:

**Competitor:**  
**What changed:**  
**Model / workload:**  
**Evidence:**  
**Why it matters:**  
**Threat / Opportunity:**  

If competitors did nothing important, do not include filler.

---

# 5. Connect the Signals

The most valuable part is connecting different signals.

Examples:

### Deployment opportunity

Model demand rising  
+  
new model released  
+  
few providers support it well  

→ benchmark and potentially deploy

### Optimization opportunity

High-demand model  
+  
SGLang/vLLM/NVIDIA optimization lands  

→ reproduce benchmark

### Competitive threat

Demand rising  
+  
competitor launches cheaper/faster endpoint  

→ investigate serving-cost gap

### Market shift

Agent usage rising  
+  
output length rising  
+  
new decode optimization appears  

→ decode optimization becomes more valuable

---

# 6. Verification

Nothing enters the report until it is traced to a primary source.

Anything that would change a decision needs **two independent sources**.

---

## Source tiers

**Tier 1 — primary, cite directly:**

- Official vendor announcement pages and model cards (`deepseek.com/news`, the HF model card **and its `config.json`**, Qwen blog, Z-AI/GLM, Moonshot/Kimi, NVIDIA docs)
- Official GitHub PRs and releases — open the PR body and read the benchmark table
- Official vendor X accounts:
  - `@deepseek_ai` · `@Alibaba_Qwen` · `@Zai_org` · `@Kimi_Moonshot`
  - `@vllm_project` · `@sgl_project` · `@lmsysorg` · `@NVIDIAAIDev`
  - `@OpenRouterAI`
- Competitor official X accounts (verify the handle in the result URL before trusting it):
  - `@wafer_ai` · `@togethercompute` · `@FireworksAI_HQ` · `@basetenco` · `@DeepInfra`
  - `@GroqInc` · `@CerebrasSystems` · `@SambaNovaAI` · `@dmatrix_ai`

**Tier 2 — usable, but label the source:**

- Inference-provider engineering blogs (Baseten, Together, Fireworks, DeepInfra, Parasail, Novita) — these are competitors; treat their performance claims as marketing until reproduced
- **Optimization-layer vendor blogs (Wafer, and anyone else selling a speedup over SGLang/vLLM)** — always read, never quote the multiplier without its setup; see section 4C
- Chip-vendor claims (Groq, Cerebras, SambaNova, d-Matrix, Positron, Etched)
- Artificial Analysis
- OpenRouter per-provider latency/throughput pages are an exception: that is **measured** third-party data, promote to Tier 1 for checking a provider's speed claim

**Tier 3 — never the sole basis for any claim:**

- Aggregator / SEO sites (tokenmaxxing, pricepertoken, llm-stats, digitalapplied, …)
- Non-official X accounts, however well-informed
- Search-result snippets

A number that exists only in Tier 3 is reported as **unverified**, or omitted.

Never launder a Tier 3 number into a bare assertion.

---

## Reaching X

- `WebFetch` on `x.com` / `twitter.com` returns **HTTP 402 Payment Required**. It does not work. Do not retry it.
- Use `WebSearch` with `allowed_domains: ["x.com"]`. Result snippets carry most of the tweet body.
- Search handle + topic. **Verify the account in the result URL is the official one** — `x.com/deepseek_ai` is official; a lookalike handle is not.
- Single tweet URLs cannot be opened, so full threads, replies and images are unreachable. If a claim lives only in a thread you cannot read, say so.
- The X index lags 1–2 days. **A silent X search is not evidence that nothing was announced.**

---

## Cross-check protocol

Before assigning **P0** or **P1** to any model, confirm it on at least two of:

1. Vendor official page or HF model card
2. Vendor official X account
3. A serving-framework PR or release that names the model

Architecture and parameter counts come from the **model card or `config.json`**, not from a tweet and not from a news article.

If the vendor page and X disagree, the vendor page wins — and note the discrepancy in the report.

---

## Known traps

- **Alias / retirement routing.** A model's rank can jump because the vendor retired the old model and routed the old name onto the new one — not because anyone chose it. **Before interpreting any rank move, check the vendor's announcements for retirement, aliasing, deprecation, or a price change.** (DeepSeek retired V4-Flash and routed `deepseek-v4-flash` → V4.1-Flash in Sept 2026; the OpenRouter position shift looked organic and was not.)
- **`openrouter.ai/rankings` is JS-rendered.** WebFetch returns the page frame without the table. Use the data API instead — `https://openrouter.ai/api/frontend/v1/rankings/models` returns one row per model-variant for the latest complete day with a `change` field (weekly by default, `?view=day` for daily), `.../rankings/tools` returns the weekly tool-call time series, `.../rankings/apps` the top apps by day/week/month. Label aggregator figures as secondary.
- **`sitemap.xml` `lastmod` is not a publication date.** It changes on any rebuild, re-publish or CMS migration, so it manufactures false in-window hits — in one run it produced false positives on five of ~25 competitor sites at once. Confirm every date from the page itself: JSON-LD `datePublished` (not `dateModified`), `article:published_time`, or the visible on-page date. If they disagree, `datePublished` wins. Dates that are simply impossible (a future year) do occur — discard the item rather than reasoning around it.
- **Kernel microbenchmark ≠ end-to-end.** A 3× TopK speedup at bs=256 / kv=1M can be 0% end-to-end on a different workload shape.
- **Functional validation ≠ performance result.** A lone tok/s figure with no baseline proves the model runs. Nothing more.
- **Token volume ≠ user count**, and neither is revenue.
- **Auto-summarized dates are unreliable.** If a release date looks off (wrong year, impossible ordering), verify it on the release page before using it to judge the 24–48h window.

---

## Provenance tags

Tag **every** number in the report:

- `[measured]` — a benchmark you read in a PR or release, with its setup stated
- `[vendor]` — the vendor's own claim
- `[3P]` — third-party claim, unverified
- `[inferred]` — your own reasoning

An untagged number is a defect.

---

# Daily Output

# INFERENCE MARKET RADAR — YYYY-MM-DD

## TL;DR

Maximum 5 bullets.

Only important changes.

---

## Demand

| Model | Signal | Change | Why it matters |
|---|---|---|---|
| Model A | High usage | ↑ | ... |
| Model B | Trending | ↑↑ | ... |

### Interpretation

In 2–4 sentences:

> Is demand actually changing?

---

## New Models

Only important models.

### Model X

Released:  
Architecture:  
Serving support:  
Demand signal:  
Inference implications:  

**Priority: P0 / P1 / P2**

---

## Serving Optimizations

Maximum 5 important items total across SGLang, vLLM, NVIDIA/TensorRT-LLM, and FlashInfer.

### Project — PR #XXXX

**Change:**  
**Benchmark:**  
**Applicable to:**  
**Why it matters:**  
**Action:** Watch / Reproduce / Port

---

## Competitors

Only include meaningful moves.

| Competitor | Change | Impact |
|---|---|---|
| X | Model Y price -30% | Competitive pressure |
| Z | New Model A support | Deployment gap |

If nothing important happened:

> No material competitor change detected.

---

## What Changed?

Answer:

> Compared with the last few days, is the inference market actually changing?

Examples:

- No structural change.
- Demand is rotating toward Model X.
- Model Y is gaining adoption unusually quickly.
- Coding-agent demand is increasing.
- Price competition around Model X is accelerating.
- A new optimization may materially change Model X serving economics.

---

## Actions

Maximum 3.

### P0 — Benchmark Model X

Why now:  
What to test:  
Metric:  
Decision criteria:

### P1 — Reproduce optimization Y

Why now:  
Expected benefit:  
Target model / hardware:

---

## Sources & Confidence

Close every report with:

- a source list (primary links: PRs, vendor pages, model cards, official X posts)
- one line stating which figures are `[measured]`, which are `[vendor]`, which are `[3P]`, and what is `[inferred]`
- anything you tried to verify and could not

---

# Research Rules

Prefer:

1. GitHub PRs / releases
2. Official model repositories
3. OpenRouter usage data
4. Artificial Analysis
5. Hugging Face
6. Official competitor pricing / documentation

Read important PRs directly.

Do not rely only on PR titles or search snippets.

Never fabricate missing numbers.

Clearly distinguish:

- measured data
- provider claim
- inference

Apply **section 6 (Verification)** to every claim before it enters the report:

- two independent sources for anything decision-changing
- architecture and parameter counts from the model card / `config.json`, never from a tweet
- check vendor announcements for retirement, aliasing or price changes before interpreting any rank move
- tag every number `[measured]` / `[vendor]` / `[3P]` / `[inferred]`

State what you could not verify. An honest gap beats a confident number.

Avoid:

- general AI news
- funding news
- generic NVIDIA news
- academic papers unrelated to production
- minor GitHub changes
- social-media hype
- long strategic essays

---

# Objective

A daily report should let a technical leader answer in less than 10 minutes:

1. What models are users moving toward?
2. What new model matters?
3. What new serving optimization matters?
4. Did a major competitor make an important move?
5. What should we benchmark or optimize next?

Everything else is noise.
