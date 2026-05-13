# frozen_string_literal: true

module BriefIntel
  class RunProcessor
    def initialize(brief_run)
      @run = brief_run
    end

    def call
      @run.update!(status: "processing", error_message: nil)
      combined = compose_combined_source
      combined = truncate_combined(combined)
      prior = PriorContextBuilder.build_for(@run)
      result = TwoStepPipeline.new(source_text: combined, prior_context: prior).call

      @run.update!(
        combined_source_text: combined,
        structured_result: result,
        status: "succeeded"
      )
    rescue ConfigurationError => e
      @run.update!(status: "failed", error_message: e.message)
    rescue ExtractionError, ValidationError, Error => e
      log_exception(e)
      @run.update!(status: "failed", error_message: user_safe_message(e))
    rescue StandardError => e
      log_exception(e)
      @run.update!(status: "failed", error_message: user_safe_message(e))
    end

    private

    def compose_combined_source
      parts = []
      if @run.user_prompt.present?
        parts << "## PM instructions\n#{@run.user_prompt.strip}"
      end

      @run.documents.blobs.each do |blob|
        body = DocumentTextExtractor.extract(blob)
        parts << "## Attachment: #{blob.filename}\n#{body.strip}"
      end

      joined = parts.join("\n\n").strip
      raise ExtractionError, "No text to process. Add instructions or documents." if joined.blank?

      joined
    end

    def truncate_combined(text)
      max = MAX_COMBINED_CHARS
      return text if text.size <= max

      head = max / 2
      tail = max - head - 80
      "#{text[0, head]}\n\n[... truncated #{text.size - head - tail} characters for processing limits ...]\n\n#{text[-tail, tail]}"
    end

    def log_exception(error)
      Rails.logger.error("[BriefIntel::RunProcessor run=#{@run.id}] #{error.class}: #{error.message}")
    end

    def user_safe_message(error)
      case error
      when ConfigurationError, ExtractionError, ValidationError
        error.message
      else
        return error.message if Rails.env.development?

        "Something went wrong while processing this brief. Try again with a smaller file or shorter text."
      end
    end
  end
end
