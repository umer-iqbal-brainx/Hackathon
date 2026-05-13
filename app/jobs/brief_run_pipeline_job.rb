# frozen_string_literal: true

class BriefRunPipelineJob < ApplicationJob
  queue_as :default

  def perform(brief_run_id)
    run = BriefRun.find_by(id: brief_run_id)
    return unless run

    BriefIntel::RunProcessor.new(run).call
  end
end
