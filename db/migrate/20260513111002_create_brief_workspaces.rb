class CreateBriefWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :brief_workspaces do |t|
      t.string :name

      t.timestamps
    end
  end
end
