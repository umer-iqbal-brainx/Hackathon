# frozen_string_literal: true

module BriefIntel
  class TwoStepPipeline
    STEP_A_SYSTEM = <<~TXT.freeze
      You are step A of a citation-first PMO pipeline. Output JSON only (no markdown fences).

      Return exactly one top-level key: "citations". Value is an array.

      Each citation object MUST have these keys:
      - "id": short stable id like "c1", "c2" (unique in this response)
      - "verbatim_excerpt": an EXACT contiguous substring copied from the SOURCE block below (must match character-for-character aside from normalization already present in SOURCE)
      - "location_hint": where this appears (e.g. "PM instructions", "Attachment: filename.pdf — page/section estimate", "paragraph ~3")
      - "neutral_summary": short factual restatement grounded ONLY in that excerpt

      Rules:
      - ONLY use the SOURCE block for new facts. A separate "Prior workspace runs" section is NOT source of truth; do not create citations from it.
      - If the SOURCE has no extractable statements, return an empty citations array.
      - Never infer requirements that are not literally supported by an excerpt.
      - Prefer fewer, high-quality citations over noisy duplicates.
    TXT

    STEP_B_SYSTEM = <<~TXT.freeze
      You are step B of a citation-first PMO pipeline. Output JSON only (no markdown fences).

      Top-level keys MUST be exactly: "tasks", "tickets", "gaps".

      "tasks": array of objects with keys:
        - "id" (t1, t2, …)
        - "title" (string)
        - "description" (string; only information traceable to cited excerpts)
        - "citation_ids" (non-empty array of citation ids from the provided citations list)
        - "acceptance_criteria" (array of strings)

      "tickets": Jira-style drafts, array of objects with keys:
        - "id" (j1, j2, …)
        - "title"
        - "issue_type" (one of: Story, Task, Bug, Spike)
        - "description"
        - "citation_ids" (non-empty array of citation ids from the provided citations list)
        - "acceptance_criteria" (array of strings)

      "gaps" — MANDATORY object with keys:
        - "confirmed_none" (boolean)
        - "justification_if_none" (string or null). If confirmed_none is true, this MUST be a non-empty string explaining why there are zero gaps OR why citations are empty.
        - "items" (array). When confirmed_none is false, items MUST be non-empty. When confirmed_none is true, items may be empty.

      Hard rules:
      - Every task and ticket MUST include at least one valid "citation_ids" entry that exists in the provided citations list.
      - If citations list is empty: tasks and tickets MUST be empty arrays; set confirmed_none=true with a clear justification_if_none, OR confirmed_none=false with items explaining missing/unclear SOURCE.
      - Never invent acceptance criteria beyond cited material; if unknown, put the uncertainty in gaps.items instead.
    TXT

    def initialize(source_text:, prior_context:, gateway: nil)
      @source = source_text.to_s
      @prior = prior_context.to_s
      @gateway = gateway || OpenAiGateway.new
      @repair_hint = nil
    end

    def call
      2.times do |attempt|
        step_a = normalize_step_a(fetch_step_a)
        step_b = normalize_step_b(fetch_step_b(step_a))
        merged = {
          "schema_version" => SCHEMA_VERSION,
          "step_a" => step_a,
          "step_b" => step_b
        }
        ResultValidator.validate!(source_text: @source, step_a:, step_b:)
        return merged
      rescue ValidationError => e
        @repair_hint = e.message
        raise if attempt >= 1
      end
    end

    private

    def fetch_step_a
      user = +<<~PROMPT
        #{prior_block}SOURCE:
        ---
        #{@source}
        ---
      PROMPT
      user << "\n\nJSON repair note: #{@repair_hint}\n" if @repair_hint.present?

      messages = [
        { role: "system", content: STEP_A_SYSTEM },
        { role: "user", content: user }
      ]
      @gateway.chat_json!(messages)
    end

    def fetch_step_b(step_a)
      citations_json = JSON.pretty_generate(step_a)
      user = +<<~PROMPT
        #{prior_block}CITATIONS_JSON (only ids listed here may be cited):
        #{citations_json}
      PROMPT
      user << "\n\nJSON repair note: #{@repair_hint}\n" if @repair_hint.present?

      messages = [
        { role: "system", content: STEP_B_SYSTEM },
        { role: "user", content: user }
      ]
      @gateway.chat_json!(messages)
    end

    def prior_block
      return "" if @prior.blank?

      "#{@prior}\n\n"
    end

    def normalize_step_a(raw)
      raise ValidationError, "step A root must be object" unless raw.is_a?(Hash)

      { "citations" => Array(raw["citations"]) }
    end

    def normalize_step_b(raw)
      raise ValidationError, "step B root must be object" unless raw.is_a?(Hash)

      gaps = raw["gaps"].is_a?(Hash) ? raw["gaps"] : {}
      gaps = {
        "confirmed_none" => false,
        "justification_if_none" => nil,
        "items" => []
      }.merge(gaps)

      {
        "tasks" => Array(raw["tasks"]),
        "tickets" => Array(raw["tickets"]),
        "gaps" => gaps
      }
    end
  end
end
