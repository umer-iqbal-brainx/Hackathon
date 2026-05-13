# frozen_string_literal: true

module BriefIntel
  class OpenAiGateway
    def self.default_client
      key = Rails.application.credentials.open_ai_key
      if key.blank?
        raise ConfigurationError, "Add open_ai_key to Rails credentials (run: bin/rails credentials:edit)."
      end

      OpenAI::Client.new(access_token: key, request_timeout: 180)
    end

    def initialize(client = nil)
      @client = client || self.class.default_client
    end

    def chat_json!(messages)
      response = @client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          response_format: { type: "json_object" },
          temperature: 0.2
        }
      )
      text = response.dig("choices", 0, "message", "content")
      raise Error, "Empty model response" if text.blank?

      JSON.parse(text)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON from model (#{e.message})"
    end
  end
end
