# frozen_string_literal: true

module RedmineWikiApproval
  module Helpers
    def view_wiki_settings_tab?(project)
      user = User.current.logged? ? User.current : User.anonymous
      return false unless user.allowed_to?(:wiki_approval_settings, project)

      # indifferent access = Strings
      s = (Setting.plugin_redmine_wiki_approval || {}).with_indifferent_access

      # true, if any is value "project"
      s.values.any? { |v| v.to_s == WikiApprovalSettingsHelper::PROJECT }
    end

    def wiki_approval_badge(status)
      case status
      when 'draft', 'canceled'
        'badge-status-locked'
      when 'pending'
        'badge-status-open'
      when 'rejected'
        'badge-private'
      when 'released', 'published'
        'badge-status-closed'
      end
    end
  end
end
