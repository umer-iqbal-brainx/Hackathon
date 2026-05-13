# frozen_string_literal: true

module BriefIntel
  class PriorContextBuilder
    def self.build_for(brief_run)
      new(brief_run).to_json_fragment
    end

    def initialize(brief_run)
      @brief_run = brief_run
      @workspace = brief_run.brief_workspace
    end

    def to_json_fragment
      prior = @workspace.brief_runs
        .where(status: "succeeded")
        .where.not(id: @brief_run.id)
        .where("created_at < ?", @brief_run.created_at)
        .order(created_at: :desc)
        .limit(3)

      runs_payload = prior.map { |run| compact_run_payload(run) }
      return "" if runs_payload.empty?

      <<~TEXT.strip
        ## Prior runs in this workspace (reference only — new facts must appear in the current SOURCE)
        #{JSON.pretty_generate(runs_payload)}
      TEXT
    end

    private

    def compact_run_payload(run)
      result = run.structured_result || {}
      step_a = result["step_a"] || {}
      step_b = result["step_b"] || {}
      gaps = step_b["gaps"] || {}

      {
        run_id: run.id,
        created_at: run.created_at.iso8601,
        citations: Array(step_a["citations"]).first(12),
        tasks: Array(step_b["tasks"]).map { |t| t.slice("id", "title", "citation_ids") },
        tickets: Array(step_b["tickets"]).map { |t| t.slice("id", "title", "citation_ids") },
        gaps_summary: {
          confirmed_none: gaps["confirmed_none"],
          items: Array(gaps["items"]).first(8)
        }
      }
    end
  end
end
