# AI provider free tiers for Tomo's BYOK pet-agent

> **Parked with the AI layer** ([ADR-0029](../adr/0029-mvp-ships-without-ai-and-never-goes-online.md), 2026-10-07). MVP ships no AI. Re-check every limit and term here before a future AI version relies on it.

**Research date: 2026-08-18.**

> **This is a snapshot, and free tiers move faster than this document.** Every
> number, model id, and limit below was read from a primary source on
> 2026-08-18. Free-tier quotas, model catalogues, and even the existence of a
> free tier change on a scale of weeks — Cerebras and GitHub Models both moved
> against us inside the last twelve months. Treat the *shapes* (error taxonomy,
> compatibility gaps, ToS structure) as durable and the *numbers* as expiring.
> Re-verify before shipping presets, and never hard-code a limit into a user-
> facing string.

## Scope and method

The question is which providers can be shipped as **presets** in Tomo's setup
flow (`Tomo_Tech_Stack_Architecture.md` §8.4), given the binding constraints:

- one hand-rolled, generic **OpenAI-compatible chat-completions client** (base
  URL + API key + model name), no vendor SDKs;
- **bring-your-own-key** — the user pastes their *own* free-tier key into a
  shipped consumer app; no first-party backend, no first-party key;
- **structured tool/function calling is mandatory** — four tools
  (`list_tasks`, `create_task`, `update_task`, `delete_task`) are sent on every
  call. No tool calling, no preset;
- **non-streaming** for MVP;
- setup makes **one cheap validation call** that must separate bad key / wrong
  model / wrong URL / no network;
- **quota exhaustion is a normal runtime condition**, so the client must
  recognise its exact wire shape.

Sources are official provider docs, API references, pricing/rate-limit pages and
ToS/AUP pages, cited inline. Where a fact is *inferred* rather than documented
it says so explicitly.

**One deviation from "documentation only":** several error shapes below were
observed by sending deliberately-invalid requests (bad key, wrong path) to the
live endpoints with `curl`. No valid API key was used and no billable inference
was performed. These are marked **[observed 2026-08-18]** and are more
trustworthy than the docs, because in two cases the docs are wrong or
incomplete about the shape.

---

## Comparison table

| Provider | Base URL (as configured) | Free without a card? | Default model to prefill | Tool calling on that model | Verdict |
|---|---|---|---|---|---|
| **Groq** | `https://api.groq.com/openai/v1` | **Yes** | `openai/gpt-oss-20b` | Yes (no parallel) | **Preset #1 — default** |
| **OpenRouter** | `https://openrouter.ai/api/v1` | **Yes** (20 RPM / 50 RPD) | `openrouter/free` | Yes (router filters for it) | **Preset #2** |
| **Google Gemini (OpenAI layer)** | `https://generativelanguage.googleapis.com/v1beta/openai` | **Yes** | `gemini-3.5-flash-lite` | Yes | **Preset #3 — with a data-use warning; ToS risk** |
| **Mistral la Plateforme** | `https://api.mistral.ai/v1` | Yes ("Free mode") | `mistral-small-latest` | Yes | **Not a launch preset** — unpublished limits, non-OpenAI error shape |
| **Self-hosted (Ollama / LM Studio)** | `http://<host>:11434/v1` / `http://<host>:1234/v1` | N/A (local) | user-supplied | Yes (Ollama ignores `tool_choice`) | **Ship as the Advanced / custom endpoint case, not a preset** |
| Cerebras | — | **No** | — | — | **Rejected**: no permanent free tier; free trial needs a verified payment method |
| GitHub Models | — | **No** | — | — | **Rejected**: fully retired 2026-07-30 |
| Together AI | — | **No** | — | — | **Rejected**: API keys require a $5 minimum credit purchase |

Rejection evidence, one line each:

- **Cerebras** — its own FAQ, verbatim: *"Is there a permanently free tier? **No.** The Free Trial is time- and credit-bounded: \$5 in credits that expire 30 days after they're granted"*, and *"If you skip adding a payment method at sign-up, Playground and API access remain inactive until you do."* ([inference-docs.cerebras.ai/support/rate-limits](https://inference-docs.cerebras.ai/support/rate-limits)) Fails the no-credit-card bar outright.
- **GitHub Models** — *"As of July 30, 2026, GitHub Models has been fully retired. The playground, model catalog, inference API, and bring your own key (BYOK) are no longer available to any customer."* ([docs.github.com](https://docs.github.com/en/github-models/use-github-models/prototyping-with-ai-models)) Does not exist.
- **Together AI** — *"API keys are not available on the limited free tier. To access API keys, you will need to add at least the minimum of \$5 in credits to your account."* ([support.together.ai](https://support.together.ai/articles/4999040689-where-to-find-your-api-key)) Fails the no-credit-card bar.

---

## 1. Groq

### 1.1 Endpoint

Base URL is `https://api.groq.com/openai/v1` — **the `/v1` is part of the
configured base URL**, and the call is `POST {base}/chat/completions`, i.e.
`https://api.groq.com/openai/v1/chat/completions`. Groq's own compatibility
page says to *"change the `base_url` to `https://api.groq.com/openai/v1`"*
([console.groq.com/docs/openai](https://console.groq.com/docs/openai)), and the
quickstart curl targets
`https://api.groq.com/openai/v1/chat/completions`
([console.groq.com/docs/quickstart](https://console.groq.com/docs/quickstart)).
Auth is `Authorization: Bearer $GROQ_API_KEY`.

Note the unusual shape: the vendor path segment `/openai` comes *before* `/v1`.
Getting this wrong is exactly the off-by-one-segment bug the ticket warns
about, and Groq detects it precisely — see §1.5.

### 1.2 Free tier

Free plan, no credit card. Groq's spend-limits page distinguishes *"paid
plans, not free tier accounts"*
([console.groq.com/docs/spend-limits](https://console.groq.com/docs/spend-limits));
nothing in the quickstart or rate-limit docs conditions free-plan API access on
a payment method. Sign up, create a key, call.

**Free Plan limits**, from the Free Plan tab of
[console.groq.com/docs/rate-limits](https://console.groq.com/docs/rate-limits):

| Model | RPM | RPD | TPM | TPD |
|---|---|---|---|---|
| `openai/gpt-oss-20b` | 30 | 1,000 | 8,000 | 200,000 |
| `openai/gpt-oss-120b` | 30 | 1,000 | 8,000 | 200,000 |
| `openai/gpt-oss-safeguard-20b` | 30 | 1,000 | 8,000 | 200,000 |
| `qwen/qwen3.6-27b` | 30 | 1,000 | 8,000 | 200,000 |
| `groq/compound`, `groq/compound-mini` | 30 | 250 | 70,000 | — |

Same page: *"Rate limits apply at the organization level, not individual
users"*, *"Cached tokens do not count towards your rate limits"*, and *"You can
hit any limit type depending on which threshold you reach first."*

**The binding constraint for Tomo is 8K TPM, not RPD.** Tomo sends four tool
schemas on every call plus conversation history. A realistic Tomo turn is
maybe 1–2K prompt tokens; the tool loop makes that *two* requests per user turn
(model emits a tool call → app feeds the result back). So 8K TPM is roughly 2–3
user turns per minute before a 429. 1,000 RPD is generous by comparison. Design
the pet's "I can't think right now" state to be triggered mostly by *TPM*, and
consider trimming history aggressively.

### 1.3 Default model and tool calling

Prefill **`openai/gpt-oss-20b`**. It is one of only two general-purpose text
models still on Groq's *Production Models* list (the other being
`openai/gpt-oss-120b`; `llama-3.3-70b-versatile` and friends have fallen off
it) — [console.groq.com/docs/models](https://console.groq.com/docs/models).

Tool support is model-level and documented in a table at
[console.groq.com/docs/tool-use](https://console.groq.com/docs/tool-use):
*"All models hosted on Groq support tool use"*, with `openai/gpt-oss-20b` and
`openai/gpt-oss-120b` marked **Local & Remote Tool Use: Yes**, **Parallel Tool
Use: No**, **JSON Mode: Yes**.

**"No parallel tool use" is a feature for Tomo, not a bug.** The agent loop
pauses on every write tool for user confirmation; a model that can only request
one tool per turn maps cleanly onto one confirmation card at a time.

`gpt-oss-20b` has a 131,072-token context and 65,536 max completion tokens
(models page), so context is never the limiting factor at 8K TPM.

### 1.4 Compatibility gaps vs the OpenAI schema

Groq publishes its OpenAPI spec inline in its docs pages; the facts below come
from the `CreateChatCompletionRequest` schema embedded in
[console.groq.com/docs/rate-limits](https://console.groq.com/docs/rate-limits)
plus the explicit gap list at
[console.groq.com/docs/openai](https://console.groq.com/docs/openai).

- **Strict schema.** `CreateChatCompletionRequest` is
  `"additionalProperties": false`. Unknown request fields are rejected, they are
  not ignored. This is the opposite of Gemini's behaviour and is the single
  most important cross-provider difference for a generic client.
- **Hard-rejected fields** (documented as *"will result in a 400 error"*):
  `logprobs`, `logit_bias`, `top_logprobs`.
- `n` must be `1` if supplied (`minimum: 1, maximum: 1`).
- **`max_tokens` is deprecated in favour of `max_completion_tokens`** but is
  still in the schema and still accepted. `max_tokens` remains the portable
  choice (see §7).
- `tool_choice` — full OpenAI `ChatCompletionToolChoiceOption` (`none` /
  `auto` / `required` / named-function object).
- `parallel_tool_calls` — present, `"default": true`. Sending `false` is legal
  and is what Tomo should do.
- `tools` — standard `{"type":"function","function":{...}}`, max 128.
- **System role is fully supported** — the quickstart's own Python sample opens
  with `{"role":"system","content":"You are a helpful assistant."}`.
- **`tool` role messages are accepted verbatim** on the follow-up turn; the
  tool-use doc's worked example posts back `{"role":"tool","tool_call_id":...,"content":...}`
  ([console.groq.com/docs/tool-use](https://console.groq.com/docs/tool-use)).
- **Temperature quirk:** *"If you set a temperature value of 0, it will be
  converted to `1e-8`"*. Harmless, but don't rely on exact-zero determinism.
- Response object is standard: `choices[].finish_reason ∈ {stop, length,
  tool_calls, function_call}`, plus Groq-only extras `x_groq`,
  `usage_breakdown`, `service_tier` which a lenient parser must tolerate.
- `service_tier` defaults to `on_demand`; don't send it.

### 1.5 Auth and failure shapes

Documented error object
([console.groq.com/docs/errors](https://console.groq.com/docs/errors)):

```json
{ "error": { "message": "String - description of the specific error",
             "type": "invalid_request_error" } }
```

The docs describe only `message` and `type`. **In practice there is also a
machine-readable `code`, and it is the field worth keying on.**

**(a) Invalid key — HTTP 401** [observed 2026-08-18]:

```json
{"error":{"message":"Invalid API Key","type":"invalid_request_error","code":"invalid_api_key"}}
```

**(c) Wrong URL / wrong path — HTTP 404** [observed 2026-08-18]:

```json
{"error":{"message":"Unknown request URL: POST /openai/v1/chat/completionsX. Please check the URL for typos, or see the docs at https://console.groq.com/docs/","type":"invalid_request_error","code":"unknown_url"}}
```

**(b) Nonexistent model — HTTP 404.** Documented status only (*"404 Not Found:
The requested resource could not be found"*). The body is **inferred** to be
the same envelope with `code: "model_not_found"`, by analogy with OpenAI's
schema and with the observed `unknown_url` code. Not verified — it needs a
valid key. *Whatever the code turns out to be, `unknown_url` already
distinguishes wrong-path from everything else, so the residual 404 is safely
treated as "wrong model".*

**(d) Quota / rate limit — HTTP 429**, documented: *"When you exceed rate
limits, our API returns a 429 Too Many Requests HTTP status code."* Headers
(from the rate-limits page):

| Header | Meaning |
|---|---|
| `retry-after` | seconds — **only present on 429** |
| `x-ratelimit-limit-requests` | always RPD |
| `x-ratelimit-limit-tokens` | always TPM |
| `x-ratelimit-remaining-requests` | always RPD |
| `x-ratelimit-remaining-tokens` | always TPM |
| `x-ratelimit-reset-requests` / `-tokens` | duration strings, e.g. `2m59.56s`, `7.66s` |

*"the other headers are always included"* — so Tomo can show a live "quota
remaining" readout without waiting for a failure, and can pre-empt the 429.

Other statuses worth handling: 422 (*"semantic errors or model hallucinations"*),
498 (flex-tier capacity — not reachable on `on_demand`), 499 (client cancelled),
5xx (*"You will not be charged for requests that return server error codes"*).

**Groq has the cleanest error classification of any candidate: status alone
separates auth (401) / not-found (404) / quota (429), and `error.code` separates
wrong-URL from wrong-model inside the 404.**

### 1.6 Cheapest validation call

```http
POST https://api.groq.com/openai/v1/chat/completions
Authorization: Bearer <key>
Content-Type: application/json

{"model":"openai/gpt-oss-20b",
 "messages":[{"role":"user","content":"hi"}],
 "max_tokens":1,
 "tools":[ ...the four real tool schemas... ]}
```

This proves key + endpoint + model in one call. Adding the real `tools` array
costs a few hundred prompt tokens but **proves the provider accepts Tomo's tool
schemas** — a malformed or unsupported schema comes back as a 400 at setup time
instead of at first chat. Because the request is strict-schema, a 400 here is
genuinely informative.

Do **not** try to force an actual tool call in the validation request
(`tool_choice: "required"` + `max_tokens: 1` would just truncate into
`finish_reason: "length"` and prove nothing). Tool-calling *capability* is a
documented model property, not something the validation call needs to exercise.
`reasoning_effort: "low"` is available on `gpt-oss-*` and keeps thinking tokens
down.

### 1.7 Terms of service

Groq is the **only** candidate whose agreement explicitly blesses the shape
Tomo needs. [Groq Services Agreement §3.1](https://console.groq.com/docs/legal/services-agreement):

> "Groq grants you a non-exclusive, non-transferable, and limited right to
> access and use the Cloud Services … **including the right to use Groq's APIs
> to integrate the Cloud Services and AI Model Services into your Customer
> Application and to make the Cloud Services and AI Model Services available to
> End Users through your Customer Applications.**"

with `"End Users"` defined as *"the end users of a Customer Application who are
authorized by Customer to access or use the Cloud Services … through such
Customer Application."*

**Training:** §4.2, verbatim —

> "**Groq is not permitted to use Inputs or Outputs for training or fine-tuning
> any AI Model Services or other models**, unless explicitly granted permission
> or instructed by Customer."

**Retention:** *"By default, Groq does not retain customer data for inference
requests"*; temporary logs only for reliability/abuse investigation, *"retained
for up to 30 days"*
([console.groq.com/docs/your-data](https://console.groq.com/docs/your-data)).

**Constraints to respect:**
- **18+.** §2: *"You must be 18 years of age or older to access or use the
  Cloud Services."* Tomo's own age gating must not be looser than this for the
  AI layer.
- §6.3(c) forbids reselling/sublicensing/distributing the Cloud Services — not
  triggered by BYOK, where the *user* is the Customer.
- The [AUP](https://console.groq.com/docs/legal/ai-policy) forbids circumventing
  limits *"including by registering multiple accounts"* — so Tomo must never
  suggest key-rotation as a quota workaround.

**Verdict: no ToS obstacle. Best privacy posture of the field.**

---

## 2. OpenRouter

### 2.1 Endpoint

Base URL `https://openrouter.ai/api/v1`; **`/v1` is in the configured base
URL**, and the call is `POST {base}/chat/completions` →
`https://openrouter.ai/api/v1/chat/completions`
([openrouter.ai/docs/quickstart](https://openrouter.ai/docs/quickstart)).
Auth is `Authorization: Bearer <key>`.

Two optional headers, `HTTP-Referer` and `X-Title`, are used for OpenRouter's
public app rankings. Both are explicitly *"Optional"* in the quickstart. Tomo
should **not** send them by default — they attribute a user's personal key
usage to a named app on a public leaderboard, which is a privacy decision the
user did not make.

### 2.2 Free tier

Free without a card. Free-model limits, taken from the constants in the
docs source at
[openrouter.ai/docs/api-reference/limits](https://openrouter.ai/docs/api-reference/limits)
(`FREE_MODEL_RATE_LIMIT_RPM = 20`, `FREE_MODEL_NO_CREDITS_RPD = 50`,
`FREE_MODEL_HAS_CREDITS_RPD = 1000`, `FREE_MODEL_CREDITS_THRESHOLD = 10`):

| Credits purchased (all time) | RPM | RPD |
|---|---|---|
| Less than $10 | 20 | **50** |
| At least $10 | 20 | 1,000 |

No TPM/TPD platform cap on free variants; per-model context limits apply.

**50 RPD is the tightest budget in the field, and Tomo's tool loop doubles the
cost of a turn** (tool call + tool-result follow-up ≈ 2 requests). Budget ~25
user turns per day. That is plausibly enough for a pet companion but must be
surfaced honestly in the preset description.

Quota state can be polled without spending a request against the model:
`GET https://openrouter.ai/api/v1/key` returns `limit_remaining`, `usage_daily`
and `is_free_tier`.

### 2.3 Default model and tool calling

Prefill **`openrouter/free`** — the Free Models Router.

> "`openrouter/free` automatically selects a free model at random from the
> available free models on OpenRouter. **The router intelligently filters for
> models that support the features your request needs, such as image
> understanding, tool calling, and structured outputs.**"
> — [openrouter.ai/docs/guides/routing/routers/free-router](https://openrouter.ai/docs/guides/routing/routers/free-router)

This is the single most churn-resistant model id available anywhere in this
research. Free model rosters turn over constantly; a router that filters on
tool-calling support means the preset does not rot. Its catalogue entry lists
`tools` and `tool_choice` in `supported_parameters` and `pricing: {prompt: "0",
completion: "0"}` ([`GET /api/v1/models`](https://openrouter.ai/api/v1/models),
queried 2026-08-18).

Its cost is non-determinism: the model actually used varies per request and is
reported back in the response's `model` field. For an in-character pet whose
persona lives in the system prompt, that's acceptable; for anything needing a
stable voice, it isn't.

**Named fallback if a stable id is wanted:** `openai/gpt-oss-20b:free`
(131,072 ctx, `tools` + `tool_choice` supported). Same underlying model as the
Groq preset, which keeps prompt-tuning transferable.

For the record, at the time of query `GET /api/v1/models` returned **415 models,
17 with a `:free` variant, 16 of which advertise `tools`** — the tool-calling
bar is not a scarcity problem on OpenRouter.

### 2.4 Compatibility gaps vs the OpenAI schema

- `tool_choice` supports `auto` / `none` / named-function objects;
  `parallel_tool_calls` is supported and *"default is true for most models"*
  ([tool-calling guide](https://openrouter.ai/docs/guides/features/tool-calling)).
- `tool` role messages are accepted verbatim — the guide's worked examples post
  back `{"role":"tool","tool_call_id":...,"content":...}`.
- System messages are standard.
- Capability is **per-model, not per-provider**: the request must only use
  parameters in that model's `supported_parameters` array. Unsupported
  parameters are normalised/dropped by OpenRouter rather than 400'd, which is
  lenient but means silent behaviour differences between routed models.
- **The big one — errors can arrive with HTTP 200.** From
  [openrouter.ai/docs/api-reference/errors](https://openrouter.ai/docs/api-reference/errors):

  > "The HTTP Response will have the same status code as `error.code`, forming a
  > request error if: Your original request is invalid; Your API key/account is
  > out of credits. **Otherwise, the returned HTTP response status will be 200
  > OK and any error occurred while the LLM is producing the output will be
  > emitted in the response body** or as an SSE data event."

  Non-streaming shape:

  ```json
  { "choices": [{ "message": {"role":"assistant","content":"partial output..."},
                  "finish_reason": "error",
                  "error": {"code":502,"message":"Provider disconnected mid-stream",
                            "metadata":{"error_type":"provider_unavailable"}} }] }
  ```

  **A generic client that only branches on HTTP status will silently treat this
  as a successful empty completion.** Tomo must check `choices[0].finish_reason
  == "error"` and `choices[0].error` on every 200.
- Upstream provider errors are surfaced through OpenRouter's own taxonomy, with
  the original code preserved in `error.metadata.provider_code`. Fallback
  routing retries other providers before the error reaches the client.

### 2.5 Auth and failure shapes

Documented envelope:

```typescript
type ErrorResponse = { error: { code: number; message: string;
                               metadata?: Record<string, unknown>; }; };
```

Note `error.code` is the **numeric HTTP status**, not a string enum — the
opposite convention to Groq. The stable machine-readable field is
`error.metadata.error_type`.

Documented `error_type` values relevant to Tomo
([errors reference](https://openrouter.ai/docs/api-reference/errors)):

| `error_type` | HTTP | Meaning |
|---|---|---|
| `authentication` | 401 | *"The API key is missing, invalid, or revoked."* |
| `payment_required` | 402 | *"The account or API key has insufficient credits."* |
| `permission_denied` | 403 | key valid, blocked by permission or guardrail |
| `not_found` | 404 | *"The requested resource (model, file, etc.) does not exist."* |
| `rate_limit_exceeded` | 429 | *"Respect the `Retry-After` header before retrying."* |
| `invalid_request` | 400 | malformed/missing parameter |
| `context_length_exceeded` | 400 | input + output exceeds the window |
| `provider_overloaded` | 503 / `provider_unavailable` 502 | upstream problem, retryable |

**Caveat, [observed 2026-08-18]: the simple platform-level errors do *not*
carry `metadata.error_type`.** Actual bodies:

- **(a) Invalid key — 401.** Malformed key: `{"error":{"message":"Missing Authentication header","code":401}}`.
  Well-formed but unknown key: `{"error":{"message":"User not found.","code":401}}`.
  Two different messages, same status, no `metadata`.
- **(c) Wrong path — 404:** `{"error":{"message":"Not Found","code":404}}` — no
  `metadata`, no way to tell it from a missing model by body alone.
- **(b) Nonexistent model — 404** with `error_type: "not_found"` per the docs;
  the body shape is **inferred** (needs a valid key to reach model resolution —
  with an invalid key OpenRouter 401s first).
- **(d) Quota — 429**, documented body:

  ```json
  { "error": { "code": 429, "message": "Rate limit exceeded",
               "metadata": { "error_type": "rate_limit_exceeded" } } }
  ```

  Headers: *"Successful inference responses do not include `X-RateLimit-*`
  headers. When OpenRouter itself returns a 429 for a platform limit, the error
  response carries `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and
  `X-RateLimit-Reset`… When every attempted provider returned a retry hint, the
  error response also carries a `Retry-After` header."* So, unlike Groq, quota
  headroom is invisible until you fail — poll `GET /api/v1/key` instead.
- **402 is a distinct case Tomo must treat as quota-like, not as an error.** A
  negative balance breaks *free* models too: *"If your account has a negative
  credit balance, you may see 402 errors, **including for free models**."*

### 2.6 Cheapest validation call

Same body as Groq (`max_tokens: 1`, one-token prompt, real `tools` array),
against `https://openrouter.ai/api/v1/chat/completions` with model
`openrouter/free`.

**But add a second, free probe:** `GET https://openrouter.ai/api/v1/key`.
It costs no inference, returns 401 on a bad key, and returns `limit_remaining`
/ `is_free_tier` on a good one. Running it *first* separates "bad key" from
"bad model / bad URL" cleanly, which the chat-completions call alone cannot do
on this provider. This is the recommended two-step validation for every
provider that offers a cheap authenticated GET — see §7.

### 2.7 Terms of service

[openrouter.ai/terms](https://openrouter.ai/terms). No clause prohibits a
third-party app accepting a user's own OpenRouter key.

- **Age 13+**, not 18+: *"You must be at least 13 years of age to use the
  Service… If you are under 18 years of age, you must have your parent or
  guardian's permission."* The friendliest age bar in the field — relevant for
  a pet-companion productivity app.
- Prohibited: *"access the Site or Service for purposes of reselling API access
  to Models or otherwise developing a competing service"*. BYOK is not
  reselling — the user pays (nothing) on their own account.
- Key handling: *"**You are responsible for maintaining the confidentiality and
  security of all API keys**, tokens, passwords, and other credentials used to
  access the Service."* Directly supports the architecture's secure-storage +
  never-log requirement.

**Training / data (default posture is good):**
[data-collection](https://openrouter.ai/docs/guides/privacy/data-collection) —

> "OpenRouter does not store your prompts or responses, *unless* you opt in…
> **Private Input & Output Logging** … Off by default. … **OpenRouter Use of
> Inputs/Outputs:** Allow OpenRouter to use your prompt and completion data to
> improve the product. In exchange, you receive a 1% discount on all model
> usage. **Off by default.**"

**One real caveat, and it matters for a free-model preset:** upstream providers
have their own policies, and the account setting that governs them is split —
*"On your account settings page, you can set whether you would like to allow
routing to providers that may train on your data (according to their own
policies). **There are separate settings for paid and free models.**"*
([provider-logging](https://openrouter.ai/docs/guides/privacy/provider-logging)).
So a `:free` route may land on a provider that trains, depending on a setting
Tomo cannot see or control. Tomo's preset description should say plainly that
free-model routing may reach providers that train on prompts, and point at
OpenRouter's privacy settings.

---

## 3. Google Gemini — OpenAI compatibility layer

### 3.1 Endpoint

Base URL is `https://generativelanguage.googleapis.com/v1beta/openai/` and the
call is `POST {base}/chat/completions` →
`https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`
([ai.google.dev/gemini-api/docs/openai](https://ai.google.dev/gemini-api/docs/openai)).
Auth is `Authorization: Bearer $GEMINI_API_KEY`.

**Path-segment precision matters here more than anywhere else.** The version
segment is `v1beta`, the vendor segment `openai` comes *after* it, and there is
**no second `/v1`**. Google's docs write the base URL *with* a trailing slash
(`.../v1beta/openai/`) because the OpenAI SDK joins with a relative path; a
hand-rolled client must normalise so that exactly one `/` separates base and
`chat/completions`. Store the preset **without** the trailing slash
(`https://generativelanguage.googleapis.com/v1beta/openai`) and always join with
`/`.

Compatibility is officially **beta**: *"Support for the OpenAI libraries is
still in beta while we extend feature support."*

### 3.2 Free tier

Free without a card. [Billing doc](https://ai.google.dev/gemini-api/docs/billing):
*"New accounts begin on the Free Tier, which allows access to certain models in
the Gemini API and AI Studio, up to the models' free tier rate limits."* The
[usage-tier table](https://ai.google.dev/gemini-api/docs/rate-limits) lists the
Free tier qualification as *"Active project or free trial"* with billing-tier
cap `N/A`, versus Tier 1's *"Set up and link an active billing account"*.

**Google no longer publishes per-model free-tier numbers in its documentation.**
The rate-limits page now says only:

> "Rate limits depend on a variety of factors (such as your usage tier) and can
> be viewed in Google AI Studio. As your tier and account status change over
> time, your rate limits will automatically update. … **Specified rate limits
> are not guaranteed and actual capacity may vary.**"

and links to `https://aistudio.google.com/rate-limit`, which requires a signed-in
Google account and is therefore not fetchable here. **RPM/TPM/RPD for the Gemini
free tier cannot be established from a public primary source as of 2026-08-18.**
Any specific figure circulating for Gemini's free tier today is secondary and
should be treated as unverified.

What *is* documented:
- RPD quotas *"reset at midnight Pacific time"*; limits are *"applied per
  project, not per API key"*.
- Spend-based rate limits: `N/A` for Free.
- Which models are free of charge, from
  [ai.google.dev/gemini-api/docs/pricing](https://ai.google.dev/gemini-api/docs/pricing) —
  **Gemini 3.7 Flash, 3.6 Flash, 3.5 Flash, 3.5 Flash-Lite and 3.1 Flash-Lite all
  show "Free of charge" in the Free Tier column** for standard interactive
  input/output. `Gemini 3.1 Pro Preview` shows "Not available" on the free tier.

### 3.3 Default model and tool calling

Prefill **`gemini-3.5-flash-lite`**. Rationale: free-of-charge on the Free Tier,
the cheapest/fastest tier of the current generation, and — critically — it
supports `thinking_level: "minimal"` via `reasoning_effort`, which the Flash and
Pro models do not all allow to be turned down. (Google's own compat examples use
`gemini-3.6-flash`; that is the reasonable Advanced-mode alternative and is also
free-of-charge.)

Tool support is model-level. The
[gemini-3.5-flash-lite model card](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite)
lists **Function calling: Supported**, Structured outputs: Supported, Thinking:
Supported. Same for
[gemini-3.6-flash](https://ai.google.dev/gemini-api/docs/models/gemini-3.6-flash).

**Thinking is a live token-budget hazard.** The troubleshooting page: *"the 2.5
Flash and Pro models … come with **thinking is enabled by default**"*, and the
compat page notes reasoning *cannot* be disabled for Gemini 2.5 Pro or 3-series
Pro models. Output pricing on the free tier is $0, but thinking tokens still
consume TPM/TPD quota. Send `reasoning_effort: "minimal"` or `"low"` — the
compat page maps `reasoning_effort` onto `thinking_level`/`thinking_budget`, and
*"If you want to disable thinking, you can set `reasoning_effort` to `"none"`"*
on the models that allow it.

### 3.4 Compatibility gaps vs the OpenAI schema

- **Unknown fields are silently ignored, not rejected** — *"Any other parameters
  not listed here or in the `extra_body` section will be silently ignored by the
  compatibility layer."* Exactly opposite to Groq. A generic client cannot rely
  on a 400 to tell it a field didn't apply; a Gemini call may quietly not do
  what you asked.
- `tools` + `tool_choice: "auto"` are the documented tool-calling form, in the
  standard `{"type":"function","function":{name, description, parameters}}`
  shape — the compat page's REST example is verbatim OpenAI.
- **`parallel_tool_calls` is not mentioned anywhere in the compatibility page.**
  Given the silent-ignore policy, sending it is harmless but may be a no-op.
  Tomo must therefore be robust to receiving *multiple* `tool_calls` in one
  assistant message from Gemini even when it asked for one. **This is a
  concrete requirement on the tool loop: handle an N-tool-call response, and
  either queue N confirmation cards or reject all but the first with a
  "declined" tool result.**
- **System messages are supported** — every Python/JS sample in the compat page
  opens with `{"role":"system", ...}`.
- `reasoning_effort` is supported and mapped to Gemini's `thinking_level` /
  `thinking_budget`.
- Gemini-only features live under `extra_body` (`cached_content`,
  `thinking_config`, safety settings, grounding). Tomo needs none of them.
- `tool` role on the follow-up turn: not shown in the compat page's tool
  example, which stops at the first response. **Unverified.** Standard OpenAI
  clients do this against Gemini routinely, but this document will not assert it
  from a primary source. Flag as a must-test-with-a-real-key item.

### 3.5 Auth and failure shapes — the worst in the field

Google documents the *native* Gemini error envelope as
`{"error": {"code": "<snake_case string>", "message": "..."}}`
([api-errors](https://ai.google.dev/gemini-api/docs/api-errors)), with codes
`authentication` (401), `model_not_found` (404), `rate_limit_exceeded` (429),
`quota_exceeded` (429, *"You have exceeded your daily quota"*),
`service_unavailable` (503), and so on. That documentation describes the
Interactions API, **not** the OpenAI compatibility layer.

**What the OpenAI compatibility endpoint actually returns** [observed
2026-08-18]:

```
POST https://generativelanguage.googleapis.com/v1beta/openai/chat/completions
Authorization: Bearer INVALID_KEY_TEST

HTTP/2 400
content-type: application/json; charset=UTF-8

[{
  "error": {
    "code": 400,
    "message": "Please pass a valid API key",
    "status": "INVALID_ARGUMENT"
  }
}
]
```

Three separate ways this breaks a naive generic client:

1. **The body is a JSON *array* wrapping the error object**, not an object.
   `json.decode(body)["error"]` throws. Every other provider returns an object.
   (The `/v1beta/openai/models` endpoint returns a bare object for the same
   failure — so the array wrapping is specific to the chat-completions path.)
2. **An invalid API key returns HTTP 400, not 401.** Any classifier that maps
   `401 → bad key` will report "wrong model" or "malformed request" to a user
   whose only mistake was a typo in their key.
3. `error.code` is a **number** (400) and the discriminating field is
   `status: "INVALID_ARGUMENT"` — a third convention, different from both Groq's
   string `code` and OpenRouter's `metadata.error_type`.

Omitting the header entirely gives the same 400/array shape with
`"message": "Missing or invalid Authorization header."`.

**(c) Wrong URL / wrong path is *indistinguishable* from a bad key.** Both
`/v1beta/openai/v1/chat/completions` (an extra `/v1`) and
`/v1beta/chat/completions` (missing `/openai`) returned the *identical*
`400 … "Please pass a valid API key"` body [observed 2026-08-18]. Google
authenticates before routing. **With an invalid key you can never learn that the
URL is wrong; with a valid key a wrong path is inferred to 404.** Setup UX must
therefore say "check your key *and* your endpoint" on this provider rather than
naming one.

**(b) Nonexistent model — inferred** to be a 404 carrying the same
array-wrapped envelope with `"status": "NOT_FOUND"`. Not verified (needs a
valid key).

**(d) Quota — HTTP 429.** Documented: *"the API returns a `429
RESOURCE_EXHAUSTED` error"* (rate-limits page) and `quota_exceeded` / 429 for
daily quota (api-errors page). **No `Retry-After` or `x-ratelimit-*` header is
documented anywhere in the Gemini docs.** The troubleshooting page's only
guidance is *"implement an exponential backoff strategy"* with *"Retry on
specific errors: only retry on transient errors (like 429, 408, or 5xx). Do not
retry on client errors (like 400 or 403)"* — advice a Tomo client cannot follow
literally, because on this provider 400 *is* the auth error.

### 3.6 Cheapest validation call

```http
POST https://generativelanguage.googleapis.com/v1beta/openai/chat/completions
Authorization: Bearer <key>

{"model":"gemini-3.5-flash-lite",
 "messages":[{"role":"user","content":"hi"}],
 "max_tokens":1,
 "reasoning_effort":"minimal",
 "tools":[ ...the four real tool schemas... ]}
```

`reasoning_effort: "minimal"` is not optional here — without it a thinking model
will burn quota tokens before hitting the 1-token output cap. Expect
`finish_reason: "length"` with empty content; that is a **success** signal.

Because unknown fields are silently ignored, the presence of the `tools` array
in a *successful* Gemini validation proves less than it does on Groq — a
malformed schema might be swallowed rather than 400'd. Tool support is
established from the model card instead.

Free GET probe available: `GET {base}/models` (documented on the compat page,
`.../v1beta/openai/models`), which separates key validity from model validity.

### 3.7 Terms of service — **this is where Gemini becomes a problem**

Three clauses in the
[Gemini API Additional Terms of Service](https://ai.google.dev/gemini-api/terms)
bear directly on Tomo, and they are the most serious ToS findings in this
research.

**(1) "Not for consumer use."** Verbatim, under Use Restrictions:

> "**Use of Google AI Studio and Gemini API is for developers building with
> Google AI models for professional or business purposes, not for consumer
> use.**"

Tomo is a consumer productivity app. Under BYOK the person who accepted these
Additional Terms is the *end user* (they got the key from AI Studio), not Tomo's
developer — which is arguably why the restriction binds them, not us. But the
same document defines an *"API Client"* as *"a website, application, or other
service"* built on the Services, which is exactly what Tomo is. **This is a
genuine grey area and should get a decision from whoever owns legal risk before
Gemini ships as a preset.**

**(2) EEA / Switzerland / UK users must be on paid.** Verbatim:

> "You may only access the Services (or make API Clients available to users)
> within an available region. **You may use only Paid Services when making API
> Clients available to users in the European Economic Area, Switzerland, or the
> United Kingdom.**"

A free-tier Gemini key used inside Tomo by a European user is, on the face of
it, outside the terms. Tomo has no way to enforce this and no first-party key to
upgrade. **This is the clause that most endangers the bring-your-own-key
pattern.**

**(3) The free tier trains on user data, and Google says not to send personal
information to it.** Verbatim, under Unpaid Services → How Google Uses Your Data:

> "When you use Unpaid Services, including … **the unpaid quota on Gemini API,
> Google uses the content you submit to the Services and any generated responses
> to provide, improve, and develop Google products and services and machine
> learning technologies** …
>
> To help with quality and improve our products, **human reviewers may read,
> annotate, and process your API input and output.** … **Do not submit
> sensitive, confidential, or personal information to the Unpaid Services.**"

Tomo's tool loop sends **task titles and notes** — a user's to-do list is
personal information almost by definition, and `list_tasks` results flow back
through the model. The pricing page states the same thing as a bullet: Free =
*"Content used to improve our products"*, Paid = *"Content **not** used to
improve our products"*.

(Partial mitigation: *"If you're in the European Economic Area, Switzerland, or
the United Kingdom, the terms under 'How Google uses Your Data' in 'Paid
Services' apply to all Services, including … unpaid quota in the Gemini API."*
So EEA/CH/UK users are protected from training — but they are also the users
told to use only Paid Services.)

Also: **18+** — *"You must be 18 years of age or older to use the APIs. You also
will not use the Services as part of a website, application, or other service
… that is directed towards or is likely to be accessed by individuals under the
age of 18."* A cute pet companion is plausibly *"likely to be accessed by"*
under-18s. Another reason to keep Gemini off the default slot.

---

## 4. Mistral la Plateforme (Free mode)

Passes both hard bars — free without a card, and tool calling — so it gets a
section, but it should **not** ship as a launch preset.

### 4.1 Endpoint

`https://api.mistral.ai/v1`, `/v1` included in the base URL, call is
`POST {base}/chat/completions`
([docs.mistral.ai — Chat Endpoints](https://docs.mistral.ai/api/endpoint/chat)).
Auth `Authorization: Bearer $MISTRAL_API_KEY`.

### 4.2 Free tier

Verbatim from
[Activate Studio and generate an API key](https://docs.mistral.ai/getting-started/quickstarts/studio/activate-and-generate-api-key):

> "**Free mode: API access is enabled by default with no credit card required.**
> Usage and rate limits apply."

**But the numbers are not published.** The
[Usage and limits](https://docs.mistral.ai/admin/user-management-finops/tier)
page says only that limits *"are shown in Admin Panel › API › Limits"*, and the
help centre confirms the axes without values: *"The API enforces three limits:
requests per second; tokens per minute: input + output throughput; tokens per
month: overall consumption cap. A 429 means you exceeded one of them. **Free
mode (the default) has the lowest limits**, intended for evaluation and
prototyping."*
([help.mistral.ai](https://help.mistral.ai/en/articles/698531-why-am-i-hitting-api-rate-limits-and-how-do-i-increase-them))

A preset whose quota Tomo cannot describe to the user is a poor preset.

Notable: *"Tiers track cumulative billing from usage, not prepaid credit
top-ups. Adding credits does not raise your rate limits"* — so there is no cheap
escape hatch when a user outgrows Free mode.

### 4.3 Default model and tool calling

`mistral-small-latest` (the model used in Mistral's own quickstart curl).
Function calling is a first-class documented capability, and the chat endpoint
schema exposes `tools`, `tool_choice` and `parallel_tool_calls`.

### 4.4 Compatibility gaps — larger than they look

From the [chat endpoint reference](https://docs.mistral.ai/api/endpoint/chat):

- **`max_tokens` only** — there is no `max_completion_tokens` in the schema.
- **`tool_choice` accepts a Mistral-only value, `"any"`**, alongside `auto` /
  `none` / `required` and the named-function object. `"any" or "required" means
  the model must call one or more tools`. Harmless if Tomo only ever sends
  `auto`, but a generic client must not assume the OpenAI enum is exhaustive.
- `parallel_tool_calls` present, default `true`.
- `messages` is typed as `SystemMessage | UserMessage | AssistantMessage |
  ToolMessage` — system and tool roles are first-class, accepted verbatim.
- Mistral-only request fields exist (`safe_prompt`, `random_seed` instead of
  `seed`, `prompt_mode`, `prompt_cache_key`, `guardrails`). Tomo needs none.
- `X-RateLimit-Remaining` response header is documented on the
  [known-limitations](https://docs.mistral.ai/resources/known-limitations) page:
  *"Check the `X-RateLimit-Remaining` response header to monitor your usage
  before hitting the limit."*
- 400 on exceeding the context window; 429 on rate limit.

### 4.5 Auth and failure shapes — **not OpenAI-shaped at all**

[observed 2026-08-18]:

- **(a) Invalid key — HTTP 401:**
  ```json
  {"detail":"Invalid API Key"}
  ```
  **There is no `error` object.** A client that does
  `body["error"]["message"]` throws on Mistral's most common failure.

- **(c) Wrong path — HTTP 404**, and the body is the API gateway's, not
  Mistral's:
  ```json
  {"message":"no Route matched with those values","request_id":"cb3f003dc151337d7c583b40e554a773"}
  ```
  A third top-level key (`message`) with no `error` and no `detail`.

- **(b) Nonexistent model** — **inferred** 400 or 404; not verified.
- **(d) Quota — HTTP 429**, documented on the known-limitations page. Body shape
  **not documented**; `Retry-After` **not documented**.

Three distinct body shapes across two failure modes, none of them the OpenAI
envelope, is a lot of bespoke parsing for a provider whose quota we can't even
quote.

### 4.6 Cheapest validation call

Mistral's own docs give it, essentially verbatim — add `max_tokens: 1` and the
tools array:

```http
POST https://api.mistral.ai/v1/chat/completions
Authorization: Bearer <key>
{"model":"mistral-small-latest","messages":[{"role":"user","content":"hi"}],"max_tokens":1,"tools":[...]}
```

### 4.7 Terms and training — ambiguous, which is itself disqualifying

Mistral's own docs contradict themselves within one page,
[Privacy and data controls](https://docs.mistral.ai/admin/monitor-comply/privacy-data-controls):

> "**API: data sent through the API isn't used for model training.**"

and, four lines later, describing the API privacy controls:

> "**Data usage for improving our services**: allow or disable the use of API
> calls to train Mistral models. If you disable this option, new interactions
> from your users aren't used to train models."

A toggle that can be *disabled* implies it is *enabled* by default, which
contradicts the flat statement above it. The help centre adds a further wrinkle:
*"If you activate Labs models, data can be used to train Mistral models,
**regardless of your subscription plan or opt-out settings**."*

**For a preset that ships user task content off-device, "the vendor's own docs
disagree about whether we train on it" is a sufficient reason not to be the
default.** Reachable via Advanced / custom endpoint for users who want it.

---

## 5. Self-hosted — the "custom endpoint" case (Ollama, LM Studio)

Not a preset with a prefilled URL, because there is no correct URL to prefill
from a phone. This is what the **Advanced / custom endpoint** escape hatch in
§8.4 exists for. Documented here because it is the only zero-quota, zero-
data-leaves-the-network option and the one privacy-conscious users will ask
for.

### 5.1 Endpoints

- **Ollama**: `http://localhost:11434/v1`, `POST {base}/chat/completions`;
  `api_key='ollama', # required but ignored`
  ([docs.ollama.com/api/openai-compatibility](https://docs.ollama.com/api/openai-compatibility)).
- **LM Studio**: `http://localhost:1234/v1`, `POST {base}/chat/completions`;
  api key `"lm-studio"`, ignored
  ([lmstudio.ai/docs/app/api/endpoints/openai](https://lmstudio.ai/docs/app/api/endpoints/openai)).

**`localhost` is wrong on a phone.** The user must enter the desktop's LAN
address, and on Ollama must start the server with `OLLAMA_HOST=0.0.0.0`.
Additionally, a plain-`http://` LAN endpoint requires an Android network-security
cleartext exception and an iOS ATS exception — **a real, non-trivial platform
task that must be budgeted if this escape hatch is to actually work.**

### 5.2 Free / limits

No quota, no key, no ToS. Bounded only by the user's hardware. Quota exhaustion
as a runtime state does not exist here — which means the error-classification
code must not assume 429 is always reachable.

### 5.3 Tool calling

Both support it. Ollama lists **Tools: ✅** for `/v1/chat/completions`. LM Studio:
*"Tool use enables LLMs to request calls to external functions and APIs through
the `/v1/chat/completions` … endpoints"*, and *"LM Studio will attempt to parse
the tool calls into the `response.choices[0].message.tool_calls` field"*
([lmstudio.ai/docs/developer/openai-compat/tools](https://lmstudio.ai/docs/developer/openai-compat/tools)).
Actual quality is entirely a function of which local model is loaded.

### 5.4 Compatibility gaps — one that forces a per-provider flag

Ollama's supported-field checklist
([docs.ollama.com/api/openai-compatibility](https://docs.ollama.com/api/openai-compatibility))
is explicit:

Supported: `model`, `messages`, `frequency_penalty`, `presence_penalty`,
`response_format`, `seed`, `stop`, `stream`, `stream_options`, `temperature`,
`top_p`, **`max_tokens`**, **`tools`**, `reasoning_effort`, `reasoning`.

Not supported: **`tool_choice`**, `logit_bias`, `user`, `n`.

- **`tool_choice` is unsupported on Ollama.** `parallel_tool_calls` and
  `max_completion_tokens` are not in the list at all. `max_tokens` *is*.
- LM Studio *does* support `tool_choice` (`none` / `auto` / `required`, the last
  llama.cpp-only), but its documented chat-completions parameter list is
  `model, top_p, top_k, messages, temperature, max_tokens, stream, stop,
  presence_penalty, frequency_penalty, logit_bias, repeat_penalty, seed` — again
  `max_tokens`, again no `max_completion_tokens`.

**Conclusion: the custom-endpoint profile must send the minimal body —
`model`, `messages`, `tools`, `max_tokens` — and omit `tool_choice` and
`parallel_tool_calls` entirely.**

### 5.5 Failure shapes

Undocumented and implementation-dependent. Practically: connection refused /
timeout (no server), and 404 from the local HTTP server for a wrong path or an
unpulled model. Tomo's classifier must degrade gracefully to "endpoint
unreachable / unexpected response" rather than assuming a JSON error envelope
exists.

### 5.6 Validation call

Same minimal body. `GET {base}/models` works on both and is the cheaper first
probe — it returns the list of locally-available models, which lets Tomo tell
"server not running" apart from "that model isn't pulled" precisely.

---

## 6. Recommendation

Ship **three presets plus the custom escape hatch**, in this order. Order is the
deliverable: the first entry is what the common user taps.

### 1. Groq — the default

The only candidate that wins on all four axes that matter:

- **Limits are published, concrete, and adequate.** 30 RPM / 1,000 RPD / 8K TPM
  / 200K TPD on `openai/gpt-oss-20b`. Tomo can tell the user exactly what they
  get.
- **Error classification is trivial.** Status alone separates auth / not-found /
  quota; `error.code` (`invalid_api_key`, `unknown_url`) resolves the ambiguous
  cases. This directly satisfies the §8.4 requirement to distinguish bad key /
  wrong model / wrong URL, with the least bespoke code of any provider.
- **Quota is observable before it bites.** `x-ratelimit-remaining-tokens` is on
  *every* response, and `retry-after` is on the 429 — so "free-tier limits are a
  normal condition, not an error" can be implemented as a *predictive* pet state
  rather than a reactive one.
- **The ToS explicitly permits the pattern.** §3.1 grants the right to make the
  Services *"available to End Users through your Customer Applications"*, and
  §4.2 forbids Groq from training on Inputs or Outputs. Nothing else in this
  research is as clean.

Watch: the 8K TPM ceiling is the real constraint — keep the tool schemas terse
and trim history. And the 18+ age requirement binds.

### 2. OpenRouter — the durable second

- `openrouter/free` is the **most churn-resistant model id in the field**: a
  router that filters for tool-calling support, so the preset survives free
  models coming and going.
- No training by default and it is an explicit opt-in with a stated incentive —
  the clearest default-off posture of any hosted candidate.
- Age 13+ rather than 18+, which suits a pet-companion app better than any other
  provider's terms.
- Costs: 50 RPD without credits is the tightest budget here (~25 Tomo turns/day
  once the tool loop doubles requests), and the **HTTP 200-with-an-error-body**
  behaviour is a genuine trap that must be handled explicitly.
- It is also the natural upgrade path: $10 of credits moves the user to 1,000
  RPD without leaving the preset.

### 3. Google Gemini — third, and only with a data-use disclosure

> **Not taken.** [#28](https://github.com/heichan2000/Tomo/issues/28) dropped
> Gemini from the presets. It stays reachable through Advanced / custom
> endpoint, with no in-app hint. The analysis below is kept as the reason.

Gemini has the most generous free allowance and the strongest models, and it is
still ranked third, on purpose:

- **Its ToS fits Tomo worst.** *"not for consumer use"*; *"You may use only Paid
  Services when making API Clients available to users in the European Economic
  Area, Switzerland, or the United Kingdom"*; 18+ and *"not … likely to be
  accessed by individuals under the age of 18"*.
- **The free tier trains on user data**, with human review, and Google's own
  terms say *"Do not submit sensitive, confidential, or personal information to
  the Unpaid Services."* Tomo's payload is the user's task list.
- **Its error shapes are the worst**: array-wrapped body, HTTP 400 for an auth
  failure, and wrong-URL indistinguishable from wrong-key.
- **Its free-tier limits are no longer publicly documented**, so the preset
  cannot honestly state what the user gets.

Ship it, because it is the free tier most users already have a key for, but:
**gate it behind an explicit one-screen notice at setup** saying task content
sent to Gemini's free tier may be used to improve Google's products and may be
read by human reviewers — and **get a decision on the EEA/UK clause before
launch.** If that decision comes back negative, drop Gemini to Advanced-only.

### 4. Advanced / custom endpoint

Ship the raw fields (base URL, key, model) with in-app hints for Ollama
(`http://<desktop-ip>:11434/v1`) and LM Studio (`http://<desktop-ip>:1234/v1`),
and the caveat that the desktop must accept LAN connections. Budget the
Android cleartext-HTTP and iOS ATS work.

### Explicitly rejected

| Provider | Grounds |
|---|---|
| **Cerebras** | No permanent free tier at all (*"Is there a permanently free tier? No."*), and the $5/30-day trial requires a verified payment method before API access activates. Fails the no-credit-card bar twice. |
| **GitHub Models** | Fully retired 2026-07-30. The API no longer exists. |
| **Together AI** | *"API keys are not available on the limited free tier"* — a $5 minimum credit purchase is required to get a key at all. Fails the no-credit-card bar. |
| **Mistral la Plateforme** | Passes both hard bars but fails on operational grounds: free-tier limits are unpublished (Admin-Panel-only), so the preset can't describe itself; the auth error is `{"detail": "..."}` with no `error` object and the 404 is a gateway body, meaning bespoke parsing for a low-value provider; and Mistral's own docs contradict themselves on whether API data trains its models. Available via Advanced. |

---

## 7. Generic-client implications

What the compatibility gaps collectively mean for the one hand-rolled client.

### 7.1 A preset is more than a URL — it is a capability profile

The naive model ("presets are just prefilled base URL + model") does not
survive contact with these four providers. A preset must carry a small
**capability profile**:

```
ProviderPreset {
  id, displayName
  baseUrl              // stored WITHOUT trailing slash; join with exactly one "/"
  defaultModel
  sendToolChoice       // false for Ollama/LM-Studio-style custom endpoints
  sendParallelToolCalls// false for custom endpoints; true (value: false) for cloud
  reasoningEffort      // "minimal" for Gemini; "low" for Groq gpt-oss; null otherwise
  strictSchema         // true for Groq — unknown fields are 400s, not ignored
  errorParser          // see 7.4
  validationProbeUrl   // optional cheap authenticated GET, e.g. {base}/models
}
```

That is four booleans and a strategy object, not a per-provider client. The
client stays generic; the *profile* is data.

### 7.2 The URL join is a real bug surface — normalise once

The four base URLs have four different shapes:

| Provider | Configured base | Vendor segment position |
|---|---|---|
| Groq | `https://api.groq.com/openai/v1` | `/openai` **before** `/v1` |
| OpenRouter | `https://openrouter.ai/api/v1` | `/api` before `/v1` |
| Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | `/openai` **after** `v1beta`, and **no** `/v1` |
| Mistral / Ollama / LM Studio | `.../v1` | plain |

**Every one of them already contains its version segment.** The rule is
therefore uniform and must be enforced in one place: *strip any trailing `/`
from the configured base, then append `/chat/completions`.* Google's docs write
their base *with* a trailing slash because the OpenAI SDK does relative-URL
resolution; a hand-rolled client that copies the doc string verbatim and
concatenates produces `//chat/completions`. Normalise on save, not on send, and
unit-test the join with and without the trailing slash.

### 7.3 Request-body fields: pick the intersection, gate the rest

- **Use `max_tokens`, not `max_completion_tokens`.** `max_tokens` is accepted by
  all six candidates. `max_completion_tokens` is absent from Mistral's schema,
  absent from Ollama's and LM Studio's supported lists, and is merely the
  *preferred* (non-exclusive) spelling on Groq. Groq deprecating `max_tokens` is
  the one thing to keep an eye on.
- **`tools`: always send, identically, everywhere.** The
  `{"type":"function","function":{name, description, parameters}}` shape is
  universal across all six.
- **`tool_choice`: send `"auto"` on cloud presets, omit on custom endpoints.**
  Ollama does not support it. Never send Mistral's `"any"`.
- **`parallel_tool_calls: false`: send on Groq / OpenRouter / Mistral, omit on
  custom endpoints.** Gemini does not document it, and silently ignores unknown
  fields — so **the tool loop must be able to receive multiple `tool_calls` in
  one assistant message regardless of what it asked for.** This is a hard
  requirement on the confirmation flow, not a nicety: N write-tool calls in one
  response must produce a deterministic outcome (queue N cards, or accept the
  first and return "user declined" tool results for the rest). Groq's
  `gpt-oss-20b` can't do parallel calls at all, so this path will be untested in
  practice unless it is unit-tested with a synthetic response.
- **Never send** `logprobs`, `top_logprobs`, `logit_bias`, `n`, `user`,
  `store`, `metadata`. Groq 400s on the first three; Ollama doesn't support the
  next three; several are documented as unsupported no-ops.
- **Do not send `temperature: 0`** — Groq rewrites it to `1e-8`, and Gemini's
  troubleshooting page warns that *"Changing these parameters (for example,
  setting the temperature below 1.0) can cause unexpected behavior, such as
  looping or degraded performance"* on Gemini 3.x. Omit temperature entirely
  and take each provider's default.
- **`reasoning_effort` is the token-budget lever**, and it is spelled the same
  on Gemini (`minimal`/`low`/`medium`/`high`, mapped to `thinking_level`), Groq
  (`low`/`medium`/`high` on `gpt-oss-*`), Mistral, and Ollama. Set it low. On a
  free tier, thinking tokens are the silent quota killer.

The asymmetry to internalise: **Groq rejects unknown fields (`additionalProperties: false`)
while Gemini silently ignores them.** So a body tuned to Gemini will 400 on
Groq, and a body tuned to Groq will silently under-configure Gemini. The
profile's field allowlist is not optional.

### 7.4 Error classification: what the logic must key on

**Status code alone is insufficient**, because Gemini returns **400** for an
invalid key. The classifier must be a two-stage function:

```
classify(transportError?, status, headers, bodyBytes, profile) -> Failure
```

**Stage 0 — transport.** Socket failure / DNS failure / timeout, before any HTTP
status → `NoNetwork`. This is the only category that is provider-independent and
the only one that is naturally unambiguous. Get it first.

**Stage 1 — body normalisation.** Four incompatible envelopes must be reduced to
one internal `{code?, message, providerType?}`:

| Shape | Producer |
|---|---|
| `{"error":{"message","type","code"}}` (`code` is a **string**) | Groq |
| `{"error":{"message","code"}}` where `code` is the **numeric HTTP status**, optional `metadata.error_type` | OpenRouter |
| `[{"error":{"code":<int>,"message","status":"INVALID_ARGUMENT"}}]` — **a JSON array** | Gemini OpenAI layer |
| `{"detail":"..."}` / `{"message":"...","request_id":"..."}` | Mistral (auth) / Mistral gateway (404) |
| non-JSON, HTML, or empty | proxies, wrong host, local servers |

The parser must therefore: accept a top-level array and take element 0; look for
`error`, then `detail`, then `message`; and **never throw on an unexpected
shape** — an unparseable body is `Unknown(status)`, not a crash. The single most
likely production crash in this whole subsystem is `body["error"]["message"]`
against Gemini or Mistral.

**Stage 2 — map to Tomo's four setup outcomes:**

| Outcome | Rule |
|---|---|
| **BadKey (auth)** | `status == 401` **OR** (`status == 400` AND the normalised message matches the profile's auth signature — Gemini: `"Please pass a valid API key"` / `"Missing or invalid Authorization header"`) **OR** Groq `code == "invalid_api_key"` **OR** OpenRouter `metadata.error_type == "authentication"` |
| **BadUrl** | `status == 404` AND (Groq `code == "unknown_url"` OR body has no recognisable `error` envelope — Mistral's `"no Route matched with those values"` is the canonical example) |
| **BadModel** | `status == 404` otherwise; OpenRouter `metadata.error_type == "not_found"`; Gemini `status == "NOT_FOUND"` |
| **QuotaExhausted (normal condition, not an error)** | `status == 429` on any provider; **plus OpenRouter `402`**, which breaks free models too |
| **NoNetwork** | stage 0 |

Two honest limitations to design the UX around:

1. **On Gemini, BadKey and BadUrl are indistinguishable** — auth is checked
   before routing, so a wrong path with a bad key returns the *bad key* message.
   The setup screen must say "check your key and endpoint" for this provider
   rather than pointing at one field. The `GET {base}/models` probe does not help
   (it fails the same way).
2. **On OpenRouter, BadKey and BadUrl are separable only by status** (401 vs
   404), and neither carries `metadata.error_type`. The documented typed-error
   vocabulary is real but appears on *inference* errors, not on platform-level
   auth/routing failures.

Both are solved the same way: **make the validation call a two-step probe** —
a cheap authenticated `GET {base}/models` (or OpenRouter's `GET /api/v1/key`)
*first* to settle key-validity, then the one-token `POST /chat/completions` to
settle model + tool-schema validity. Failure of step 1 → BadKey or BadUrl;
success of step 1 and failure of step 2 → BadModel. This turns an ambiguous
one-call classification into an unambiguous two-call one, for the price of one
extra free request at setup only.

### 7.5 Runtime quota handling

The 429 path is a *normal state*, and the information available to it varies
sharply:

| Provider | `Retry-After` | Quota headroom before failure |
|---|---|---|
| Groq | Yes, on 429 | **Yes — `x-ratelimit-remaining-tokens` on every response** |
| OpenRouter | Yes, when upstream provided a hint | No headers on success; poll `GET /api/v1/key` |
| Gemini | **Not documented** | No |
| Mistral | Not documented | `X-RateLimit-Remaining` documented |
| Ollama / LM Studio | N/A | N/A |

So: **read `Retry-After` when present, fall back to exponential backoff with
jitter when absent** (Google's explicit recommendation), and **cap retries** —
the pet's "I can't think right now" state is the correct terminal outcome, not
an infinite retry loop. On Groq specifically, Tomo can pre-emptively enter a
"resting" pet state when `x-ratelimit-remaining-tokens` drops below one turn's
worth, which is a nicer experience than failing mid-sentence.

### 7.6 Response parsing

- `choices[0].message.tool_calls` and `finish_reason ∈ {stop, length,
  tool_calls}` are universal. `finish_reason: "length"` on a `max_tokens: 1`
  validation call is a **success**, not a failure — thinking models will always
  produce it.
- **A 200 is not proof of success on OpenRouter.** Check `choices[0].finish_reason
  == "error"` and `choices[0].error` before treating a 200 as a completion. This
  check is cheap and harmless on every other provider, so make it
  unconditional rather than profile-gated.
- Tolerate unknown response fields — Groq adds `x_groq`, `usage_breakdown`,
  `service_tier`; OpenRouter adds `provider` and `openrouter_metadata`; Gemini
  adds reasoning fields. Decode leniently.

### 7.7 Testability

Every fact in §7.4 is a pure function of `(status, headers, body)` and can be
unit-tested from captured fixtures with no network and no key. The observed
error bodies in §1.5, §2.5, §3.5 and §4.5 are exactly those fixtures — copy them
verbatim into the test suite. This keeps the error-classification logic inside
the "owned, provider-agnostic, fully-testable code" boundary the architecture
asks for, and it means adding a fifth provider later is a fixture plus a profile
row, not a new code path.

---

## Open questions requiring a real API key

Everything below is marked *inferred* or *unverified* above and should be
confirmed empirically during implementation:

1. Gemini: is `{"role":"tool", "tool_call_id":..., "content":...}` accepted
   verbatim on the follow-up turn of the OpenAI compatibility layer?
2. Gemini: exact body and status for a nonexistent model with a valid key
   (expected: 404, array-wrapped, `"status":"NOT_FOUND"`).
3. Gemini: current free-tier RPM/TPM/RPD from the signed-in AI Studio rate-limit
   page — Tomo cannot describe this preset honestly without it.
4. Gemini: does the compat layer honour `parallel_tool_calls`, or silently
   ignore it and emit multiple tool calls anyway?
5. Groq: the `error.code` string for a nonexistent model (expected
   `model_not_found`).
6. OpenRouter: the exact 404 body for a nonexistent model with a valid key —
   specifically whether `metadata.error_type` is populated there.
7. Mistral: 429 body shape and whether `Retry-After` is sent.
8. All: whether `GET {base}/models` returns 401 (rather than 200 with a filtered
   list) on an invalid key — this is the load-bearing assumption behind the
   two-step validation probe in §7.4.

## Legal decisions required before launch

1. **Gemini's *"not for consumer use"* restriction** — does shipping a Gemini
   preset in a consumer app breach it, given the key belongs to the user?
2. **Gemini's EEA / Switzerland / UK paid-only clause** — Tomo cannot enforce
   it and has no paid path. Does the Gemini preset need to be region-gated, or
   dropped?
3. **Gemini's 18+ / "not likely to be accessed by under-18s" clause** versus a
   pet-companion app's likely audience.
4. **Groq's 18+ requirement** versus Tomo's own age policy for the AI layer.
5. Whether the free-tier training disclosure (Gemini; possibly Mistral;
   possibly OpenRouter's free-model routing) belongs in Tomo's privacy policy as
   well as in the setup screen.
