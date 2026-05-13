# frozen_string_literal: true

module BriefIntel
  SCHEMA_VERSION = 1
  OPENAI_MODEL = "gpt-4.1-mini"
  MAX_COMBINED_CHARS = 120_000
  MAX_FILE_BYTES = 15.megabytes
  MAX_FILES = 8
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
  ].freeze

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ExtractionError < Error; end
  class ValidationError < Error; end
end
