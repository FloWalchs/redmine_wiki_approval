# frozen_string_literal: true

class AddWikiApprovalWorkflow < ActiveRecord::Migration[5.2]
  def self.up
    create_table :wiki_approval_workflows do |t|
      t.integer :wiki_page_id, null: false
      t.integer :wiki_version_id, null: false
      t.integer :author_id, null: false
      t.integer :status, null: false, default: 0
      t.text :note
      t.timestamps null: false
    end

    add_index :wiki_approval_workflows, :status
    add_index :wiki_approval_workflows, [:wiki_page_id, :wiki_version_id], unique: true, name: "idx_waw_page_and_version"
    add_foreign_key(
      :wiki_approval_workflows,
      :users,
      column: :author_id
    )
    add_foreign_key(
      :wiki_approval_workflows,
      :wiki_pages,
      column: :wiki_page_id
    )

    create_table :wiki_approval_workflow_steps do |t|
      t.references :wiki_approval_workflow, null: false
      t.integer :step, null: false
      t.references :principal, polymorphic: true, null: false, index: false
      t.integer :step_type, null: false, default: 0
      t.text :note
      t.integer :status, null: false, default: 0
      t.timestamps null: false
    end

    add_index :wiki_approval_workflow_steps, :status
    add_index :wiki_approval_workflow_steps, [:principal_type, :principal_id], name: 'idx_waw_steps_principal'
    add_foreign_key(
      :wiki_approval_workflow_steps,
      :wiki_approval_workflows,
      column: :wiki_approval_workflow_id
    )
  end

  def self.down
    drop_table :wiki_approval_workflow_steps
    drop_table :wiki_approval_workflows
  end
end
