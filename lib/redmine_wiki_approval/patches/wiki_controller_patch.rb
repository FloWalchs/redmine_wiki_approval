# frozen_string_literal: true

require_dependency 'wiki_controller'

module RedmineWikiApproval
  module Patches
    module WikiControllerPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods

        after_action :wiki_approval_save, only: [:update]
        append_before_action :set_wiki_approval_data, only: [:show, :edit]
      end

      module InstanceOverwriteMethods
        def set_wiki_approval_data
          return unless @project && RedmineWikiApproval.is_enabled?(@project)

          # draft or approval must be enabled in project or plugin
          setting = WikiApprovalSetting.find_or_create(@project.id)
          return unless RedmineWikiApproval.approval_or_draft_enabled?(@project, setting)

          approval = WikiApprovalWorkflow.for_wiki(@page.id, params[:version].nil? ? @page.version : params[:version].to_i).first

          @wiki_approval_data = {
            view_version_id: params[:version].nil? ? @page.version : params[:version].to_i,
            approval: approval,
            latest_public_approval: WikiApprovalWorkflow.latest_public_version(@page.id).first,
            setting: setting,
            step_approval: WikiApprovalWorkflowSteps.first_pending_step_for(approval, User.current, @project, params[:step_id])
          }
        end

        def wiki_approval_save
          # check params
          status = params[:status]
          return true unless status

          status_disabled = params[:status_disabled]
          return true unless status_disabled

          return unless User.current.allowed_to?(:wiki_draft_create, @project)

          version = params[:version].present? ? params[:version].to_i : @page.version

          approval = WikiApprovalWorkflow.find_or_initialize_by(
            wiki_page_id: @page.id,
            wiki_version_id: version
          )

          approval.status = params[:status]
          approval.author_id ||= User.current.id
          approval.save!
        end
      end
    end
  end
end
