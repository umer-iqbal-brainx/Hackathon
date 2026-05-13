# frozen_string_literal: true

module BriefIntel
  class ResultValidator
    def self.validate!(source_text:, step_a:, step_b:)
      new(source_text:, step_a:, step_b:).validate!
    end

    def initialize(source_text:, step_a:, step_b:)
      @source = source_text.to_s
      @step_a = step_a
      @step_b = step_b
    end

    def validate!
      raise ValidationError, "step_a must be a hash" unless @step_a.is_a?(Hash)
      raise ValidationError, "step_b must be a hash" unless @step_b.is_a?(Hash)

      citations = Array(@step_a["citations"])

      citations.each do |c|
        raise ValidationError, "citation missing keys" unless c.is_a?(Hash) && %w[id verbatim_excerpt location_hint neutral_summary].all? { |k| c.key?(k) }

        excerpt = c["verbatim_excerpt"].to_s
        raise ValidationError, "citation #{c['id']} excerpt empty" if excerpt.blank?

        unless substring_of_source?(excerpt)
          raise ValidationError, "citation #{c['id']} verbatim_excerpt not found in SOURCE (citation-first violation)"
        end
      end

      citation_ids = citations.map { |c| c["id"].to_s }.to_set
      tasks = Array(@step_b["tasks"])
      tickets = Array(@step_b["tickets"])
      gaps = @step_b["gaps"]

      raise ValidationError, "step_b.tasks must be array" unless tasks.is_a?(Array)
      raise ValidationError, "step_b.tickets must be array" unless tickets.is_a?(Array)
      raise ValidationError, "step_b.gaps must be object" unless gaps.is_a?(Hash)

      unless gaps.key?("confirmed_none") && gaps.key?("items")
        raise ValidationError, "gaps must include confirmed_none and items"
      end

      items = Array(gaps["items"])
      confirmed = gaps["confirmed_none"] == true || gaps["confirmed_none"].to_s == "true"
      justification = gaps["justification_if_none"]

      if confirmed
        raise ValidationError, "gaps.confirmed_none true requires justification_if_none" if justification.to_s.strip.empty?
      elsif items.empty?
        raise ValidationError, "When confirmed_none is false, gaps.items must be non-empty"
      end

      if citation_ids.empty?
        raise ValidationError, "tasks must be empty when there are no citations" if tasks.any?
        raise ValidationError, "tickets must be empty when there are no citations" if tickets.any?
      end

      [ tasks, tickets ].each do |collection|
        collection.each do |row|
          row_ref = row["id"].presence || row["title"].presence || "row"
          ids = Array(row["citation_ids"]).map(&:to_s)
          raise ValidationError, "#{row_ref} missing citation_ids" if ids.empty?

          unknown = ids.reject { |id| citation_ids.include?(id) }
          raise ValidationError, "#{row_ref} cites unknown #{unknown.join(', ')}" if unknown.any?
        end
      end

      true
    end

    private

    def substring_of_source?(excerpt)
      norm = ->(s) { s.to_s.unicode_normalize(:nfc).gsub(/\u00a0/, " ").squeeze(" \t").strip }
      n_src = norm.call(@source)
      n_ex = norm.call(excerpt)
      return true if n_src.include?(n_ex)

      flex_src = n_src.gsub(/\s+/, " ")
      flex_ex = n_ex.gsub(/\s+/, " ")
      flex_src.include?(flex_ex)
    end
  end
end
