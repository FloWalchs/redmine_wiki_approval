# frozen_string_literal: true

module RedmineWikiApproval
  module Patches
    module NotifiablePatch
      extend ActiveSupport::Concern

      def all
        notifications = super
        notifications << Redmine::Notifiable.new('wiki_approval_notifications')
        notifications
      end
    end
  end
end
