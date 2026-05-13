# frozen_string_literal: true

class BriefWorkspacesController < ApplicationController
  def index
    @brief_workspaces = BriefWorkspace.order(updated_at: :desc).limit(100)
  end

  def show
    @brief_workspace = BriefWorkspace.find(params[:id])
    @brief_runs = @brief_workspace.brief_runs.limit(50)
  end

  def new
    @brief_workspace = BriefWorkspace.new
  end

  def create
    @brief_workspace = BriefWorkspace.new(brief_workspace_params)
    if @brief_workspace.save
      redirect_to @brief_workspace, notice: "Workspace created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def brief_workspace_params
    params.require(:brief_workspace).permit(:name)
  end
end
