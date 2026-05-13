# frozen_string_literal: true

require "csv"

module BriefIntel
  class CsvExporter
    def initialize(brief_run)
      @run = brief_run
    end

    def to_csv
      result = @run.structured_result || {}
      step_a = result["step_a"] || {}
      step_b = result["step_b"] || {}
      citations = Array(step_a["citations"])
      citation_index = citations.index_by { |c| c["id"].to_s }

      CSV.generate(headers: true) do |csv|
        csv << %w[
          record_type
          id
          title
          description
          issue_type
          citation_ids
          verbatim_citations
          acceptance_criteria
          gap_topic
          gap_reason
          suggested_question
        ]

        Array(step_b["tasks"]).each do |t|
          csv << task_row(t, citation_index, "task")
        end

        Array(step_b["tickets"]).each do |t|
          csv << task_row(t, citation_index, "ticket")
        end

        gaps = step_b["gaps"] || {}
        Array(gaps["items"]).each do |g|
          csv << [
            "gap",
            g["id"],
            g["topic"],
            g["reason"],
            nil,
            nil,
            nil,
            nil,
            g["topic"],
            g["reason"],
            g["suggested_question"]
          ]
        end

        if gaps["confirmed_none"]
          csv << [
            "gaps_summary",
            "confirmed_none",
            "No open gaps (per model)",
            gaps["justification_if_none"].to_s,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil
          ]
        end
      end
    end

    private

    def task_row(row, citation_index, record_type)
      ids = Array(row["citation_ids"]).map(&:to_s)
      verbatim = ids.filter_map { |id| citation_index[id]&.fetch("verbatim_excerpt", nil) }.join("\n---\n")
      issue_type = record_type == "ticket" ? row["issue_type"] : nil
      [
        record_type,
        row["id"],
        row["title"],
        row["description"],
        issue_type,
        ids.join("; "),
        verbatim,
        Array(row["acceptance_criteria"]).join(" | "),
        nil,
        nil,
        nil
      ]
    end
  end
end
