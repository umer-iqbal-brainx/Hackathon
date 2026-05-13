# frozen_string_literal: true

class BriefRunsController < ApplicationController
  before_action :set_brief_workspace

  def new
    @brief_run = @brief_workspace.brief_runs.new
  end

  def create
    @brief_run = @brief_workspace.brief_runs.new(brief_run_params)
    attach_documents

    if @brief_run.save
      BriefRunPipelineJob.perform_later(@brief_run.id)
      redirect_to [ @brief_workspace, @brief_run ], notice: "Brief queued for processing."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @brief_run = @brief_workspace.brief_runs.find(params[:id])
    @structured = @brief_run.structured_result || {}
    @step_a = @structured["step_a"] || {}
    @step_b = @structured["step_b"] || {}
  end

  def export_csv
    @brief_run = @brief_workspace.brief_runs.find(params[:id])
    unless @brief_run.succeeded?
      redirect_to [ @brief_workspace, @brief_run ], alert: "CSV is available after a successful run."
      return
    end

    csv = BriefIntel::CsvExporter.new(@brief_run).to_csv
    send_data csv,
      filename: "brief_run_#{@brief_run.id}_export.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  private

  def set_brief_workspace
    @brief_workspace = BriefWorkspace.find(params[:brief_workspace_id])
  end

  def brief_run_params
    params.require(:brief_run).permit(:user_prompt)
  end

  def attach_documents
    files = params.dig(:brief_run, :documents)
    return if files.blank?

    @brief_run.documents.attach(files)
  end
end
