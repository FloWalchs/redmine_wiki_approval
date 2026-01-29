# frozen_string_literal: true

class AddWikiApprovalWorkflow < ActiveRecord::Migration[7.2]
  def self.up
    create_table :wiki_approval_workflows do |t|
      t.references :wiki_page, null: false, foreign_key: { to_table: :wiki_pages }, index: false
      t.references :wiki_version, null: false, index: false
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.text :note
      t.timestamps null: false
    end

    add_index :wiki_approval_workflows, :status, name: 'index_wiki_workflows_on_status'
    add_index :wiki_approval_workflows, [:wiki_page_id, :wiki_version_id],
              unique: true,
              name: 'index_wiki_workflows_on_page_version'

    create_table :wiki_approval_workflow_steps do |t|
      t.references :wiki_approval_workflow, null: false, foreign_key: { to_table: :wiki_approval_workflows }
      t.integer :step, null: false
      t.references :principal, polymorphic: true, null: false
      t.integer :step_type, null: false, default: 0
      t.text :note
      t.integer :status, null: false, default: 0
      t.timestamps null: false
    end

    add_index :wiki_approval_workflow_steps, :status, name: 'index_wiki_workflow_steps_on_status'
  end

  def self.down
    drop_table :wiki_approval_workflow_steps
    drop_table :wiki_approval_workflows
  end
end
