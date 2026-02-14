# frozen_string_literal: true

module RedmineWikiApproval
  module Patches
    module WikiPagePatch
      extend ActiveSupport::Concern

      included do
        has_many :wiki_approval_workflows, 
                class_name: 'WikiApprovalWorkflow',
                foreign_key: :wiki_page_id,
                dependent: :destroy    
      end
    end
  end
end
