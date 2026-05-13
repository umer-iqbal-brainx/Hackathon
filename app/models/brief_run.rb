# frozen_string_literal: true

class BriefRun < ApplicationRecord
  belongs_to :brief_workspace, touch: true

  has_many_attached :documents

  STATUSES = %w[queued processing succeeded failed].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :source_present, on: :create
  validate :acceptable_documents

  def in_progress?
    status.in?(%w[ queued processing ])
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end

  private

  def source_present
    return if user_prompt.present? || documents.attached?

    errors.add(:base, "Add PM instructions and/or attach at least one document.")
  end

  def acceptable_documents
    return unless documents.attached?

    if documents.count > BriefIntel::MAX_FILES
      errors.add(:documents, "too many files (maximum is #{BriefIntel::MAX_FILES})")
    end

    documents.each do |attachment|
      blob = attachment.blob
      next if blob.blank?

      unless BriefIntel::ALLOWED_CONTENT_TYPES.include?(blob.content_type)
        errors.add(:documents, "#{blob.filename} has unsupported type (#{blob.content_type})")
      end

      if blob.byte_size > BriefIntel::MAX_FILE_BYTES
        errors.add(:documents, "#{blob.filename} exceeds #{(BriefIntel::MAX_FILE_BYTES / 1.megabyte).to_i} MB")
      end
    end
  end
end
