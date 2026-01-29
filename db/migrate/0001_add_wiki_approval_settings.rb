# frozen_string_literal: true

class AddWikiApprovalSettings < ActiveRecord::Migration[7.2]
  def self.up
    create_table :wiki_approval_settings do |t|
      t.references :project, null: false
      t.text :json_data
      t.timestamps null: false
    end
    add_index :wiki_approval_settings, :project_id, name: 'index_wiki_approval_settings_project'
  end

  def self.down
    drop_table :wiki_approval_settings
  end
end
