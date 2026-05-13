# frozen_string_literal: true

module BriefIntel
  class DocumentTextExtractor
    def self.extract(blob)
      new(blob).extract
    end

    def initialize(blob)
      @blob = blob
    end

    def extract
      case @blob.content_type
      when "application/pdf"
        extract_pdf
      when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        extract_docx
      when "text/plain"
        @blob.download.force_encoding("UTF-8")
      else
        raise ExtractionError, "Unsupported type #{@blob.content_type} for #{@blob.filename}"
      end
    end

    private

    def extract_pdf
      @blob.open do |file|
        reader = PDF::Reader.new(file)
        reader.pages.map(&:text).join("\n\n")
      end
    rescue PDF::Reader::MalformedPDFError => e
      raise ExtractionError, "Could not read PDF (#{@blob.filename}): #{e.message}"
    end

    def extract_docx
      io = StringIO.new(@blob.download)
      Docx::Document.open(io, &:text)
    rescue StandardError => e
      raise ExtractionError, "Could not read DOCX (#{@blob.filename}): #{e.message}"
    end
  end
end
