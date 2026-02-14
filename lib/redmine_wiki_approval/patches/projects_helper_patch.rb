# frozen_string_literal: true

require_dependency 'projects_helper'

module RedmineWikiApproval
  module Patches
    module ProjectsHelperPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def project_settings_tabs
          tabs = super

          if view_wiki_settings_tab?(@project)
            action = {
              name:       'wiki_approval',
              controller: 'wiki_approval_settings',
              action:     :show,
              partial:    'settings/show_project',
              label:      :label_wiki_approval
            }
            tabs << action
          end

          tabs
        end
      end
    end
  end
end
