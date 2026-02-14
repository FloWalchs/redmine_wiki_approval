# frozen_string_literal: true

class AddWikiApprovalWorkflowStatuses < ActiveRecord::Migration[5.2]
  def self.up

    create_table :wiki_approval_workflow_statuses do |t|
      t.references :wiki_approval_workflow, null: false, index: { name: 'idx_wawstatuses_workflow_id' }
      t.integer :status, null: false, default: 0
      t.integer :author_id, null: false
      t.datetime :created_at, null: false
    end

    add_foreign_key(
      :wiki_approval_workflow_statuses,
      :wiki_approval_workflows,
      column: :wiki_approval_workflow_id,
      name: 'fk_wawstatuses_workflow'
    )

  end

  def self.down
    drop_table :wiki_approval_workflow_statuses
  end
end