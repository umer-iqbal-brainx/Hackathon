# frozen_string_literal: true

class BriefWorkspace < ApplicationRecord
  has_many :brief_runs, -> { order(created_at: :desc) }, dependent: :destroy, inverse_of: :brief_workspace

  validates :name, length: { maximum: 255 }, allow_blank: true

  def display_name
    name.presence || "Workspace ##{id}"
  end
end
