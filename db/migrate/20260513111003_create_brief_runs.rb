class CreateBriefRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :brief_runs do |t|
      t.references :brief_workspace, null: false, foreign_key: true
      t.text :user_prompt
      t.text :combined_source_text
      t.string :status, null: false, default: "queued"
      t.text :error_message
      t.jsonb :structured_result

      t.timestamps
    end

    add_index :brief_runs, %i[brief_workspace_id status]
    add_index :brief_runs, :created_at
  end
end
