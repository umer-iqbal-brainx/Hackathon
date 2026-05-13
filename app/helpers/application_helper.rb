# frozen_string_literal: true

module ApplicationHelper
  def brief_status_badge_class(status)
    case status
    when "succeeded" then "bg-success-subtle text-success-emphasis border border-success-subtle"
    when "failed" then "bg-danger-subtle text-danger-emphasis border border-danger-subtle"
    when "processing" then "bg-primary-subtle text-primary-emphasis border border-primary-subtle"
    when "queued" then "bg-warning-subtle text-warning-emphasis border border-warning-subtle"
    else "bg-secondary-subtle text-secondary-emphasis border border-secondary-subtle"
    end
  end
end
