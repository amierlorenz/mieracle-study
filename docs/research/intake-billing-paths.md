# Paying for intake: Claude subscription (via Claude Code) vs Gemini API

Research for issue #74 (map: #70). Researched 2026-10-02 against Claude Code 2.1.288 on this Mac.

**Decision already made by the user:** support both paths behind one swappable provider. This note covers whether that works, what the terms say, how to estimate per-step cost (as session % on the subscription path, dollars on Gemini), and whether live usage can be read.

## Answer in brief

| | Claude subscription via `claude -p` | Gemini API |
|---|---|---|
| Works from the app? | Yes, on **macOS only**. The app spawns the unmodified `claude` binary as a subprocess. Not possible on iOS. | Yes, on macOS and iOS (plain HTTPS + API key from the Keychain). |
| Terms | Permitted for personal use, as far as the documents say (quotes below). Third-party apps that route *other people's* subscriptions are forbidden. Not legal advice. | Standard API key use. Free tier content **is** used by Google to improve products; paid tier content is not. |
| Marginal cost | $0 until plan limits run out; it uses the same 5-hour and weekly limits as the user's normal Claude and Claude Code use. | Pay per token, from a prepaid balance (min $5). |
| Per-step estimate | Session % only by calibration. Anthropic publishes no token-to-% mapping. Before/after deltas are measurable at 1% resolution. | Exact dollars: count tokens first, multiply by the published price, and read the real `usage` afterwards. |
| Live usage readable? | **Yes.** Session % and weekly % can be read two ways (verified on this machine, see below). | No remaining-quota API is documented. The balance and spend cap are visible only in AI Studio. The app can track its own spend from `usage`. |

## 1. Claude subscription path

### 1.1 What the terms say (exact text)

**Consumer Terms of Service** (effective Oct 8, 2025; these govern Free, Pro and Max), Section 3, item 7, from the list of things you may not do:

> "Except when you are accessing our Services via an Anthropic API Key or where we otherwise explicitly permit it, to access the Services through automated or non-human means, whether through a bot, script, or otherwise."
> https://www.anthropic.com/legal/consumer-terms

Section 2: "You may not share your Account login information, Anthropic API key, or Account credentials with anyone else."

**Claude Code docs, Legal and compliance** (https://code.claude.com/docs/en/legal-and-compliance):

- License: Claude Code use by Free, Pro and Max users is under the Consumer Terms.
- Acceptable use: "Advertised usage limits for Pro and Max plans assume ordinary, individual usage of Claude Code and the Agent SDK."
- Authentication and credential use:
  > "**OAuth authentication** is intended exclusively for purchasers of Claude Free, Pro, Max, Team, and Enterprise subscription plans and is designed to support ordinary use of Claude Code and other native Anthropic applications."
  >
  > "**Developers** building products or services that interact with Claude's capabilities, including those using the Agent SDK, should use API key authentication through Claude Console or a supported cloud provider. Anthropic does not permit third-party developers to offer Claude.ai login into their own applications, or to route requests through Free, Pro, or Max plan credentials on behalf of their users. Moreover, developers may not collect, store, or intermediate Claude.ai credentials or session tokens — sign-in to a Claude account must complete through Anthropic's own flow."
  >
  > "Nor does it prevent an end user from signing in to the unmodified Claude Code binary with their own Claude subscription [...]"
  >
  > "Anthropic reserves the right to take measures to enforce these restrictions and may do so without prior notice."

**Agent SDK overview** (https://code.claude.com/docs/en/agent-sdk/overview):

> "Unless previously approved, Anthropic does not allow third party developers to offer claude.ai login or rate limits for their products, including agents built on the Claude Agent SDK."

The same page says: "To drive the same agent loop from a language other than Python or TypeScript, run the CLI as a subprocess with the `-p` flag and `--output-format json`."

**Reading** (not legal advice):

- The automation ban in the Consumer Terms has an exception: "where we otherwise explicitly permit it". Anthropic's own docs explicitly document `claude -p` headless runs. They also say Pro/Max limits assume "ordinary, individual usage of Claude Code and the Agent SDK". So scripted `claude -p` by the subscriber, for themselves, is a contemplated use.
- The developer restrictions are about offering Claude login, or routing through plan credentials, "on behalf of their users". MieracleStudy has one user, who is also the account owner, and it is not distributed. The app never sees credentials. It runs the unmodified binary, which signs in through Anthropic's own flow (`/login`). That matches the carve-out quoted above for "an end user [...] signing in to the unmodified Claude Code binary with their own Claude subscription".
- **Where it turns gray:** heavy bulk traffic stops being "ordinary, individual usage", and Anthropic can enforce without notice. Distributing the app with this path enabled would clearly break the rules.

**Guardrails to keep it on the right side:**
- Never read, copy or forward Claude credentials or tokens (Keychain items, `~/.claude*`). Only exec `claude`.
- Never call claude.ai or Anthropic usage endpoints directly. Get usage only from the CLI's own outputs (§1.3).
- Keep it personal and undistributed. Keep the Gemini path working as a fallback.

### 1.2 Mechanics (from https://code.claude.com/docs/en/headless and https://code.claude.com/docs/en/cli-reference, plus probes on this Mac)

- Invocation (macOS only): `Process` with `executableURL` set to the absolute path (`~/.local/bin/claude` here). GUI apps don't inherit the shell `PATH`. App Sandbox is off, so this is allowed.
- **Remove `ANTHROPIC_API_KEY` (and `ANTHROPIC_AUTH_TOKEN`) from the child environment.** Otherwise Claude Code bills the API key instead of the subscription. Support article: "If you have an ANTHROPIC_API_KEY environment variable set on your system, Claude Code will use this API key for authentication instead of your Claude subscription [...]" (https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan).
- **Don't use `--bare`.** The docs say: "bare mode doesn't use your subscription login" and "In bare mode, Claude Code never reads OAuth credentials or the system keychain."
- Recommended flags for an intake step:
  `claude -p --output-format json --no-session-persistence --tools "" --setting-sources "" --strict-mcp-config --model <m> --system-prompt "<intake instructions>" --json-schema '<schema>'`
  - `--json-schema` makes the result arrive in `structured_output`. Verified: `{"word":"OK"}`.
  - `--tools ""` with `--setting-sources ""` and `--strict-mcp-config` keeps hooks, MCP, CLAUDE.md and skills out. `--system-prompt` replaces the large default prompt. Measured on Haiku: with the default prompt, the trivial call cost 6,543 cache-write tokens. With `--system-prompt`, it took 1,126 input tokens. Use the replacement to save subscription usage.
  - For PDFs or long source files, allow only the read tool (`--tools Read --allowedTools Read`) and pass the file path, or pipe text on stdin (stdin is capped at 10 MB).
  - Prompt text goes in as an argument or on stdin. Never put secrets on the command line.
- The result JSON includes `total_cost_usd`, `usage` and per-model `modelUsage` (input, output, cache and thinking tokens, plus `costUSD` with `"costBasis":"list"`). The docs call these "client-side estimates". On a subscription the dollars are notional, but the token counts are real.
- The `system/init` stream event reports `"apiKeySource":"none"` when the subscription is in use. Check it to confirm the run is not billing an API key.
- Exit code 0 means success. Failures such as auth errors are printed as the result on stdout. A `system/api_retry` event's `error` can be `rate_limit`, `billing_error`, `authentication_failed`, and others.

### 1.3 Reading live session and weekly usage: yes, two ways

**A. `claude -p "/usage" --output-format json`.** This runs locally and costs nothing: on this machine it returned `num_turns: 0` and `total_cost_usd: 0`. Its `result` text contained:

```
You are currently using your subscription to power your Claude Code usage
Current session: 20% used · resets Oct 3 at 1:50am (America/New_York)
Current week (all models): 40% used · resets Oct 7 at 6am (America/New_York)
```

This is human-readable text, so the parse is fragile. The SDK reference confirms that a command such as `/usage` sent as a prompt returns its output as the result. The costs doc warns: "When the request for your plan limits fails, most often because the usage endpoint is rate limited, `/usage` shows the last usage bars it loaded", so cache the result and don't poll it often.

**B. The `rate_limit_event` in `--output-format stream-json --verbose`.** Every real call emits one. Observed on this machine:

```json
{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1791006600,"rateLimitType":"five_hour",
 "overageStatus":"rejected","overageDisabledReason":"out_of_credits","isUsingOverage":false,
 "unifiedWindows":{"five_hour":{"utilization":0.21,"resetsAt":1791006600},
                   "seven_day":{"utilization":0.39,"resetsAt":1791367200}}}}
```

The documented type (`SDKRateLimitEvent`, https://code.claude.com/docs/en/agent-sdk/typescript) lists only `status` (`allowed` | `allowed_warning` | `rejected`), `resetsAt`, `utilization` and the credits fields. **`unifiedWindows` and `rateLimitType` are observed but undocumented**, so decode them optionally. Resolution is 0.01, i.e. 1%. This is the best source because it comes free with every step.

The status-line JSON also has documented `rate_limits.five_hour/seven_day.used_percentage` fields (https://code.claude.com/docs/en/statusline), but only for interactive sessions, so it doesn't help here.

### 1.4 Per-step cost estimate in session %

- Anthropic publishes **no** mapping from tokens to session %, and limits differ by plan and model (https://support.claude.com/en/articles/11145838). The limits are also shared: "all activity in both tools counts against the same usage limits", so other Claude use moves the same meter.
- Practical design:
  1. **Measure:** record `five_hour.utilization` before and after each step, from the first and last `rate_limit_event`, plus the step's `modelUsage.costUSD` at list price. Show "this step used ≈ N% of the session".
  2. **Estimate before running:** keep a rolling ratio of (Δ session %) to (list-price USD) per model, fit over many steps. Then estimate % as list-USD × ratio. List-USD comes from a token estimate × Anthropic list price, e.g. Haiku 4.5 at $1/$5, Sonnet 5.5 at $2/$10, Opus 5.5 at $4/$20 per MTok. Show it as a range, e.g. "~1–3% of session", because the meter moves in 1% steps and other Claude use adds noise.
  3. Show the live session % and weekly %, with reset times, from §1.3 next to the estimate.
- `--max-budget-usd` caps notional list-price spend, not plan %. It can still serve as a per-step runaway guard.

## 2. Gemini API path

Sources: https://ai.google.dev/gemini-api/docs/pricing (updated 2026-10-01), /billing, /rate-limits (updated 2026-09-02), /document-processing, /tokens, /interactions.

- **Prices** (paid tier, per 1M tokens, text, standard):
  - `gemini-3.8-flash`: $0.75 in / $3.75 out through Dec 31 2026, rising to $1.50 / $7.50 from Jan 1 2027.
  - `gemini-3.5-flash`: $1.50 / $9.00.
  - `gemini-3.5-flash-lite`: $0.30 / $2.50.
  - `gemini-3.1-pro-preview`: $2.00 / $12.00 for prompts up to 200k tokens; no free tier.
  - Output price includes thinking tokens. Batch is 50% off.
- **Free tier** exists for the Flash models, but: "Content used to improve our products" on free and "Content **not** used to improve our products" on paid. Study material is personal but not secret. Still, for a paid-quality path, the user should enable billing.
- **Billing:** paid tier means linking a billing account and **prepaying at least $5**. "When your Prepay credit balance on the billing account hits $0, all API keys in all projects linked to that billing account will stop working simultaneously", and requests return HTTP 402. There is an approximately 10-minute billing lag, so overages are possible. Prepaid credits expire after 12 months. Project spend caps can be set in AI Studio (Spend page; experimental).
- **Rate limits:** RPM, TPM and RPD per tier. Tier 1 needs active billing and has a $250 cap. Limits are visible "in AI Studio". The docs describe no API for remaining quota or balance, so the app can't read live balance or quota; it can only sum its own `usage`.
- **Per-step estimate:** exact. Call `countTokens` (or estimate PDFs at 258 tokens per page, max 1000 pages or 50 MB) × list price before the step. Read `usage` (Interactions API: `total_input_tokens` / `total_output_tokens`) afterwards and keep a running total.
- **API surface:** Google now recommends the **Interactions API** (`POST https://generativelanguage.googleapis.com/v1beta/interactions`) for new projects, with structured output via `response_format` `{mime_type: "application/json", schema: …}`. `generateContent` "remains fully supported". Set `store=false`, because Interactions stores requests by default. Use plain `URLSession`; there is no official Swift server SDK.

## 3. Fit with the existing `AIProvider`

`MieracleKit/Sources/MieracleKit/AI/AIProvider.swift` defines task-specific methods (`grade`, `rephrase`, `explainChoice`, `suggestShortName`, `generatePrompts`) plus `isAvailable`, with `FoundationModelsProvider` as the only conformer. It has no notion of cost, usage or attachments.

Recommendation: don't stretch `AIProvider` for intake. Add a lower-level backend that both intake and, optionally, `AIProvider` adapters can sit on:

```swift
public protocol LLMBackend: Sendable {
    var id: BackendID { get }                     // .claudeSubscription, .gemini
    var isAvailable: Bool { get }                 // claude binary present (macOS) / Gemini key in Keychain
    func estimate(_ request: LLMRequest) async throws -> CostEstimate
    func run<T: Decodable & Sendable>(_ request: LLMRequest, as: T.Type) async throws -> LLMResult<T>
    func usage() async -> UsageSnapshot?          // nil for Gemini
}

public enum CostEstimate: Sendable { case dollars(Double), sessionPercent(ClosedRange<Double>) }
public struct UsageSnapshot: Sendable { var session: Double; var sessionResets: Date; var week: Double; var weekResets: Date }
```

`LLMRequest` carries the system prompt, user text, a JSON Schema and optional file attachments. `LLMResult` carries the decoded value, token counts, list-price USD, and for Claude the before/after `UsageSnapshot`.

- `ClaudeCodeBackend` is `#if os(macOS)` only. It drives `Process`, scrubs the environment, decodes the stream-json `rate_limit_event`, and decodes the result.
- `GeminiBackend` takes its key from `KeychainStore`.

This keeps the file layout rules: logic in `MieracleKit/AI/`, selection state in a `Services/` observable.

## 4. Checklist for #75 "Set up intake accounts"

- [ ] Confirm the `claude` CLI is installed and signed in **with the subscription** (`/login` in an interactive session). Note the absolute path, `~/.local/bin/claude` here.
- [ ] Confirm that `claude -p "/usage" --output-format json` prints "using your subscription".
- [ ] Make sure no `ANTHROPIC_API_KEY` is set globally, or plan for the app to strip it.
- [ ] Optional: turn usage credits on or off on claude.ai under Settings > Usage, depending on whether intake may spill into paid overage. They are currently off.
- [ ] Create a Google AI Studio project and Gemini API key. Link billing and prepay $5 to reach the paid tier, so content is not used for training. Set a project monthly spend cap. Consider auto-reload.
- [ ] Enter the Gemini key only in the app's Settings, which stores it in the Keychain via `KeychainStore`. Never put it in source or env files committed to the repo.
- [ ] Pick default models, e.g. `gemini-3.8-flash` (promo price ends Dec 31 2026) and Claude `sonnet`/`haiku` for the subscription path.

## 5. Open points and caveats

- The issue bodies of #74 and #70 could not be read from this agent: `gh` needs `zsh -ic` and the worktree guard blocked it. This note follows the ticket summary given in the task.
- `unifiedWindows` in `rate_limit_event` and the `/usage` text format are undocumented or human-oriented and may change. Decode defensively and fall back to "usage unavailable".
- Session % estimates are statistical. Expect ±1–2% noise from the 1% resolution and from other Claude use.

## Sources

- Consumer Terms: https://www.anthropic.com/legal/consumer-terms
- Claude Code legal and compliance: https://code.claude.com/docs/en/legal-and-compliance
- Headless / `-p`: https://code.claude.com/docs/en/headless
- Agent SDK overview: https://code.claude.com/docs/en/agent-sdk/overview
- Agent SDK TS reference (`SDKRateLimitEvent`, result fields): https://code.claude.com/docs/en/agent-sdk/typescript
- Status line `rate_limits`: https://code.claude.com/docs/en/statusline
- Costs and `/usage`: https://code.claude.com/docs/en/costs, https://code.claude.com/docs/en/commands
- Pro/Max with Claude Code: https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan
- Gemini: https://ai.google.dev/gemini-api/docs/pricing, /billing, /rate-limits, /document-processing, /tokens, /interactions, /structured-output
- Local probes (Claude Code 2.1.288): `claude -p "/usage" --output-format json`, a stream-json Haiku call, and a `--json-schema` + `--system-prompt` Haiku call.
