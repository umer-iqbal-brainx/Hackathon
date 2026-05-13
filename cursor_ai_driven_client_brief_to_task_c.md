# AI-driven client brief to task converter
_Exported on 5/13/2026 at 16:33:54 GMT+5 from Cursor (3.2.21)_

---

**User**

Explain below task to me

AI-Powered Client Brief → Dev-Ready Tasks / Jira Tickets Converter

Objective
Build an AI-driven system that transforms raw, unstructured client briefs into:

Clear, structured, developer-ready task breakdowns
Automatically generated developer tickets


The goal is to  build a tool for PMO department which will eliminate ambiguity, reduce back-and-forth communication, and enable developers to start implementation immediately. The system must never make assumptions. Instead.

Points to consider : 


No authentication is required

---

**Cursor**

Here is a plain-language breakdown of what that task is asking for.

## What you are building

A **PMO-facing tool** that takes a **raw client brief** (emails, PDFs, meeting notes, bullet lists — often vague or incomplete) and turns it into:

1. **Structured work breakdown** — clear phases, features, tasks, dependencies, and acceptance-style criteria in language developers can use.
2. **Ready-to-file tickets** — items shaped like **Jira issues** (title, description, type, maybe labels/priority) so they can be pasted or pushed into Jira with minimal editing.

The **outcome** is faster handoff from “what the client said” to “what engineering should do,” with less interpretation drift and less PM ↔ dev ↔ client ping-pong.

## What “no assumptions” really means

The brief says the system **must not invent requirements**. In practice that usually implies:

- **Only restate or decompose what is supported by the brief** (and any attached facts you explicitly allow, e.g. a glossary).
- **Surface gaps explicitly** — e.g. “Not specified: API rate limits,” “Unclear: who approves UAT,” “Missing: supported browsers.”
- **Prefer questions or ‘blocked’ sections** over guessing defaults (e.g. don’t assume “React” or “two-week sprint” unless the brief says so).

So the value is not “smart guessing,” it is **rigorous structuring + visible uncertainty**.

## “No authentication is required”

That is a **scope simplifier**: you do not need login, roles, or user accounts for v1. Typical implications:

- Treat it as **internal-only** or behind **network controls** (VPN, office IP), because unauthenticated tools can leak briefs if exposed publicly.
- You still need to think about **who can hit the API** and **where data is stored**, even without user logins.

## What success looks like for PMO

- Brief in → **checklist of dev tasks + draft Jira tickets** out.
- **Ambiguity is listed**, not hidden inside confident-sounding text.
- Developers can **start implementation** where the brief is complete, and **ask targeted questions** only where the output flags gaps.

If you want to go deeper next, we can separate this into **product flows** (upload → review gaps → export) vs **technical pieces** (LLM prompt design, schema for tasks/tickets, Jira API vs CSV export) — say which angle you care about.

---

**User**

what should be the structure explain in simple points don't give extra explanations and then i will update the structure then we will build it in this rails 8 application by keep in mind that our task should be production ready 

if you have any question regaring this for batter understanding you can ask

---

**Cursor**

## Suggested structure (simple points)

**1. Input**
- How the brief enters the app (paste text, upload file, or both)
- Optional metadata (client name, project name, date) if you want traceability

**2. Processing**
- Call to the AI layer with a fixed output schema (tasks + tickets + gaps)
- Validation that output matches that schema before saving/showing

**3. Output model (what you store)**
- Original brief (raw text + optional file reference)
- Parsed result: structured tasks, draft Jira-style tickets, explicit “gaps / questions” list
- Status: draft / accepted / exported (or similar)

**4. User flow (PMO)**
- Create run → review AI result → edit in UI (optional) → export or copy

**5. Integrations**
- Export: CSV, clipboard, and/or Jira API (pick what v1 is)
- API keys / env config for AI and Jira (if used)

**6. Ops / production**
- Logging (no secrets in logs), rate limits, timeouts, retries for AI
- Background job for long briefs
- Basic abuse/size limits (max chars, max file size)

**7. Security (even without auth)**
- CSRF on forms, strong params, sanitize stored HTML if any
- Secrets only in env / credentials; brief data encrypted at rest if your stack supports it

**8. Tests**
- Request/service specs for parsing + validation; fixtures for sample briefs

---

## Questions (short)

1. **Input**: text only, or also **PDF/DOCX**?
2. **Jira**: **API create issues** in a real project, or **CSV / copy-paste** for v1?
3. **Persistence**: keep **history** of all runs per “project,” or single-use sessions?

---

**User**

answers of your questions
Input: text and also PDF/DOCX can accept all
CSV / copy-paste for v1
Persistence: i think we should Persist it so next prompt can check it

let me know if you still have any quesiton other wise create a proper plan and give to me if i approve it then you can build it by the way i will add open ai key in creaditional file with name "open_ai_key" and you have to use open ai 4.1 mini model to do this task for document conversion

---

**Cursor**

Checking the Rails app setup so the plan matches your stack.



Here is a **concrete plan** aligned with your answers (text + PDF/DOCX, CSV/copy-paste v1, persisted for follow-up prompts, `open_ai_key` in credentials, model **`gpt-4.1-mini`**).

---

## Plan (for your approval)

### 1) Scope (v1)
- **In**: pasted text **and/or** uploaded **PDF/DOCX** (reject other types with a clear error).
- **Out**: structured **tasks**, **Jira-style ticket drafts**, and an explicit **gaps/questions** list (no invented requirements).
- **Export**: **CSV download** + **copy-to-clipboard** (no Jira API).
- **Persistence**: everything saved so a **later prompt in the same “workspace”** can load prior runs as context.

### 2) Domain model (PostgreSQL + `jsonb`)
- **`BriefWorkspace`** (name optional): groups related work for “next prompt checks prior output.”
- **`BriefRun`**: one generation attempt.
  - `workspace_id`, `user_prompt` (text the PM typed), `combined_source_text` (extracted + pasted merged), `status` (`queued/processing/succeeded/failed`), `error_message` (safe text), timestamps.
  - **`structured_result` (`jsonb`)**: versioned payload, e.g. `{ "tasks": [...], "tickets": [...], "gaps": [...], "unsupported_claims": [...] }` (exact keys fixed in code).
- **Active Storage**: attachments on `BriefRun` (original files); keep originals for audit/re-download.

### 3) Ingestion pipeline (production-safe)
- Validate **MIME/extension**, **max file size**, **max total chars** after extraction.
- **`ExtractDocumentTextJob` (Solid Queue)**: PDF via **`pdf-reader`**, DOCX via **`docx`** (or equivalent maintained gem).
- Merge: `user_prompt + "\n\n" + extracted_text` → `combined_source_text` (truncate with explicit marker if over limit).

### 4) AI integration
- Gem: **`ruby-openai`** (official-style Ruby client; widely used).
- **Credentials**: `Rails.application.credentials.open_ai_key` (as you specified).
- **Model constant**: `gpt-4.1-mini` (OpenAI API id for “4.1 mini”).
- **Service object** (single place): builds system instructions (“never assume; mark gaps; only derive from provided text”), sends `combined_source_text`, requests **JSON-only** output matching a strict internal schema; **parses + validates** before saving `structured_result`.
- On invalid JSON / schema mismatch: fail the run with a user-visible, non-leaky error and log server-side detail.

### 5) Web UI (Hotwire + Bootstrap, no auth)
- Pages:
  - **Workspaces index/create**
  - **Workspace show**: list runs + “New run”
  - **Run show**: status (Turbo stream/poll while processing), rendered sections (tasks/tickets/gaps), **CSV** button, **Copy** buttons (per section + full JSON if useful).
- UX: show **processing** state immediately; no blocking request on OpenAI in the web thread (job does work).

### 6) “Next prompt can check it” behavior
- When starting a **new `BriefRun`** in the same workspace, include **compact context** from the **latest succeeded run** (and optionally last N): e.g. prior `structured_result` summary + prior `gaps` + short excerpt of `combined_source_text` capped by tokens—implemented deterministically in Ruby, not guessed by the model beyond what you pass in.

### 7) CSV v1
- One CSV export definition (e.g. **tickets** as rows: `title, description, acceptance_criteria, dependencies, source_excerpt, gap_flag`) plus optional second sheet/tab later; v1 can be **single CSV** with a `record_type` column (`task` vs `ticket`) if simpler.

### 8) Production hardening (minimum bar)
- **Rate limiting** (Rack::Attack or Rails 8 built-in where applicable) even without auth (abuse/size).
- **Timeouts** around OpenAI calls; **retries** only where safe (network), not on bad prompts.
- **Structured logging** without logging full briefs by default (configurable).
- **DB indexes**: `brief_runs.workspace_id`, `brief_runs.status`, `brief_runs.created_at`.

### 9) Tests
- Model validations + attachment rules.
- Text extraction unit tests with tiny fixture PDF/DOCX.
- Service spec with **VCR/WebMock** (or stubbed client) for OpenAI response parsing/validation.

### 10) Implementation order
1. Migrations + models + Active Storage + validations  
2. Extraction job + guards  
3. OpenAI service + schema validation + persist results  
4. Turbo UI + CSV + copy  
5. Workspace context packaging for follow-up runs  
6. Tests + polish  

---

## One remaining question (optional)
- For follow-ups, do you want the model to treat prior runs as **“ground truth to refine”** (iterate tickets) or **“reference only”** (new brief additions must still be quoted from new text)? Default in the plan: **reference + explicit user prompt wins**, never silently changing old facts unless the new prompt cites them.

If you **approve this plan**, reply **“approved”** (and answer the optional question only if you care strongly either way). After approval I can implement it in your Rails app using `open_ai_key` + `gpt-4.1-mini`.

---

**User**

answer of your last question
 two-step, citation-first pipeline with a mandatory “gaps” path.
and we will not add tests cases for that and you can run every thing in your internal console for the command to run while implementation
and create beautiful according to industry standard ui/ux using bootstrap 5 and scss 
let me know if you still have any question

---

**Cursor**

Here is how I will treat your answer, plus anything still worth deciding.

## Citation-first, two-step pipeline + mandatory gaps

- **Step A (citations)**: Model returns only **source-grounded items** — each item includes **verbatim or near-verbatim excerpt + location hint** (e.g. paragraph/snippet id) and a short **neutral paraphrase**. Anything not clearly supported stays **out** of this list.
- **Step B (work items)**: Model maps **only Step A citations** into **tasks** and **Jira-style tickets**. Every task/ticket must **reference one or more citation ids** (no orphan work items).
- **Mandatory gaps path**: A dedicated **Gaps / needs client input** section is **always emitted** (can be empty only if the model explicitly states **“none found”** with a one-line justification tied to the brief). Unsupported or vague phrases go here, not into tickets.

Follow-ups in a workspace: **new user text is primary**; prior runs are **context** for consistency, not a license to invent new facts.

## Your other constraints

- **No automated tests** for this feature (I will still run the app and jobs manually via commands in the terminal as we go).
- **UI**: Bootstrap **5** + **SCSS**, clean professional layout (spacing, typography, states for queued/processing/succeeded/failed, clear hierarchy for citations → tickets → gaps, accessible copy/CSV actions).

## Questions from me

**None blocking.** Optional only: do you want a **default workspace** on first visit (less clicking), or always **“create workspace”** first? If you do not care, I will use **create workspace first** (clearer audit trail).

---

If you want me to start changing the Rails app, reply **approved** or **go ahead** (per your earlier rule). I will use **`Rails.application.credentials.open_ai_key`** and model **`gpt-4.1-mini`**.

---

**User**

approved

---

**Cursor**

Implementing the approved plan: exploring the Rails app structure, then adding models, services, jobs, and UI.



Implementing: adding dependencies, generating migrations, and creating models, services, jobs, controllers, views, and styles.



Implementing core logic, updating the migration, removing generated tests that would break CI, and adding the UI layer.



Here is what was implemented and how to run it.

### Implemented

- **Persistence**: `BriefWorkspace` and `BriefRun` (status `queued` → `processing` → `succeeded` / `failed`), `structured_result` as `jsonb`, **Active Storage** for PDF / DOCX / TXT.
- **Pipeline**: `BriefRunPipelineJob` → `BriefIntel::RunProcessor` (extract text, truncate to **120k** chars) → **`BriefIntel::TwoStepPipeline`** (OpenAI **`gpt-4.1-mini`**, JSON mode) → **`BriefIntel::ResultValidator`** (verbatim excerpt ⊆ source, every task/ticket cites real ids, **mandatory gaps** rules) with **one automatic retry** on validation failure (repair note passed back into the prompts).
- **Context**: `BriefIntel::PriorContextBuilder` injects the last **3** successful runs in the same workspace (reference-only block).
- **UI**: Bootstrap **5** + SCSS (`_brief_intel.scss`), navbar, hero, cards, status badges, spinner + meta refresh while processing, citations / tasks / tickets / gaps layout, **Stimulus** `clipboard` for copy.
- **Export**: **CSV** (`BriefIntel::CsvExporter`) + copy actions; no Jira API.
- **Gems**: `ruby-openai`, `pdf-reader`, `docx`, **`csv`** (Ruby 3.4+ needs it explicitly).

### Your OpenAI key

Run `bin/rails credentials:edit` and add a **top-level** key:

```yaml
open_ai_key: sk-...
```

The app reads it as `Rails.application.credentials.open_ai_key`.

### Commands to run locally

Your `Procfile.dev` only runs JS/CSS watchers (no web). In practice:

1. **Terminal A** — app server:  
   `cd rails_app && bin/rails server`
2. **Terminal B** — assets (if you change SCSS/JS):  
   `cd rails_app && bin/dev`  
   or once: `yarn build && yarn build:css`
3. DB is already migratable via **`bin/rails db:prepare`** (done successfully here).

Jobs use the **async** adapter in development by default, so the pipeline runs in-process after requests without a separate worker.

### Files to know

| Area | Path |
|------|------|
| Model | `app/models/brief_run.rb`, `brief_workspace.rb` |
| Job | `app/jobs/brief_run_pipeline_job.rb` |
| Services | `app/services/brief_intel/` |
| UI | `app/views/brief_*`, `app/assets/stylesheets/_brief_intel.scss` |
| Routes | `config/routes.rb` (root → workspaces index) |

If anything fails in the browser (e.g. **`allow_browser versions: :modern`** in `ApplicationController`), say what browser you use and we can adjust that line.

