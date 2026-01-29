# frozen_string_literal: true

module RedmineWikiApproval
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        RedmineWikiApproval.setup!
      end
    end
  end
end