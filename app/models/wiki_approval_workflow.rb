# frozen_string_literal: true

class WikiApprovalWorkflow < ApplicationRecord
  self.table_name = 'wiki_approval_workflows'
  attr_accessor :_status_changed_in_txn

  belongs_to :wiki_page
  belongs_to :wiki_version, class_name: 'WikiContent::Version'
  belongs_to :author, class_name: 'User'

  has_many :approval_steps, class_name: 'WikiApprovalWorkflowSteps', dependent: :destroy, inverse_of: :approval
  validates :status, presence: true
  after_create :cancel_old_approvals

  after_update :mark_status_changed
  after_commit :notify_status_change, on: [:update]

  enum :status, {
    canceled: 5,
    draft: 10,
    pending: 20,
    rejected: 40,
    published: 60,
    released: 70,
  }

  scope :by_author, ->(user_id) { where(author_id: user_id) }
  scope :for_wiki, ->(page_id, version_id) {
    where(wiki_page_id: page_id, wiki_version_id: version_id)
  }
  scope :latest_public_version, ->(page_id) {
    where(wiki_page_id: page_id, status: [statuses[:published], statuses[:released]])
      .order(id: :desc)
      .limit(1)
  }

  def steps_grouped_with_default
    grouped = approval_steps.group_by(&:step)

    # 2. steps from last released-version
    if grouped.blank?
      grouped = WikiApprovalWorkflow
                  .where(wiki_page_id: wiki_page_id, status: :released)
                  .order(wiki_version_id: :desc)
                  .first
                  &.approval_steps
                  &.group_by(&:step) || {}
    end

    # when step 1 is not there, default value
    grouped[1] ||= [approval_steps.build(step: 1, step_type: :or)]

    grouped
  end

  def self.latest_public_from_version(page_id, from_version)
    where(
      wiki_page_id: page_id,
      status: [statuses[:published], statuses[:released]],
      wiki_version_id: ...from_version
    )
    .order(id: :desc)
    .limit(1)
    .pick(:wiki_version_id) || 1
  end

  def cancel_old_approvals
    old_ids = WikiApprovalWorkflow
                .where(wiki_page_id: wiki_page_id)
                .where(wiki_version_id: ...wiki_version_id)
                .where(status: WikiApprovalWorkflow.statuses[:pending])
                .pluck(:id)

    return if old_ids.empty?

    ActiveRecord::Base.transaction do
      # old Approvals canceln
      WikiApprovalWorkflow.where(id: old_ids)
                            .update_all(status: WikiApprovalWorkflow.statuses[:canceled])

      # Steps canceln
      WikiApprovalWorkflowSteps.where(wiki_approval_workflow_id: old_ids)
                        .where(status: WikiApprovalWorkflowSteps.statuses[:pending])
                        .update_all(status: WikiApprovalWorkflowSteps.statuses[:canceled],
                                    updated_at: Time.current)
    end
  end

  def mark_status_changed
    # one time per transaction
    self._status_changed_in_txn ||= saved_change_to_status?
  end

  def notify_status_change
    return unless self._status_changed_in_txn || saved_change_to_status?
    # only if higher then pending, no draft, no canceled
    return unless self.class.statuses[status] >= self.class.statuses[:pending]

    WikiApprovalMailer.deliver_wiki_approval_state(self, wiki_page, User.current)
  end

  def project
    wiki_page.wiki.project
  end

  def event_group
    "wiki_page:#{wiki_page_id}"
  end

  # activity how it look like
  acts_as_event \
    title: ->(o) do
      label    = I18n.t(:label_wiki_approval_workflow, default: 'Approval workflow')
      ver_num  = o.wiki_version_id
      "Wiki-#{label}: #{o.wiki_page.title} #{ver_num ? " (##{ver_num})" : ''}"
    end,
    author:      :author,
    description: ->(o) do
      ver_num = o.wiki_version_id
      version_from = WikiApprovalWorkflow.latest_public_from_version(o.wiki_page_id, o.wiki_version_id)
      diff_path = "/projects/#{o.wiki_page.project.identifier}/wiki/#{ERB::Util.url_encode(o.wiki_page.title)}/diff" \
                  "?version=#{ver_num}&version_from=#{version_from}"
      desc = +""
      desc << "#{I18n.t("wiki_approval_workflow.status.#{o.status}", default: o.status)} · "
      if Setting.text_formatting == 'textile'
        desc << "(\"#{I18n.t(:label_diff)}\":#{diff_path})"
      else
        desc << "(<a href=\"#{diff_path}\">#{I18n.t(:label_diff)}</a>)"
      end
      desc << "\n\n#{o.note}" if o.note.present?

      grouped = o.approval_steps.group_by(&:step)
      # grouped sorted Step-Nr
      grouped.sort_by { |step, _| step.to_i }.map do |step, steps|
        step_type = I18n.t("wiki_approval_#{steps.first&.step_type}", default: '')
        # Step 1* User 1* User 2
        # Step 2* User 3* User 4
        desc << "\n\n#{I18n.t(:label_wiki_approval_step, default: 'Step')} #{step} #{step_type ? " - (#{step_type})" : ''}"
        steps.map do |s|
          desc << "\n* #{s.principal&.name}"
          desc << " (#{I18n.t("wiki_approval_workflow_steps.status.#{s.status}", default: 'rejected')})" if s.rejected?
          desc << "\n #{s.note}" if s.note.present?
        end
      end

      desc.html_safe
    end,
    datetime:    :updated_at,
    project: ->(o) { o.wiki_page.wiki.project },
    url: ->(o) do
      {
        controller:  'wiki',
        action:      'show',
        project_id:  o.wiki_page.wiki.project,
        id:          o.wiki_page.title,
        version:     o.wiki_version_id
      }.compact
    end,
    group: ->(o) { "wiki_page:#{o.wiki_page_id}" }

  # activity which entrys filtering
  acts_as_activity_provider \
    type:       'wiki_approval_workflow',
    permission: :wiki_draft_view,
    author_key: :author_id,
    timestamp:  :updated_at,
    scope: proc { |options = {}, _user = nil|
      rel = joins(wiki_page: { wiki: :project })
            .includes(wiki_page: { wiki: :project })

      if (project = options[:project]).present?
        ids = options[:with_subprojects] ? project.self_and_descendants.select(:id) : project.id
        rel = rel.where(projects: { id: ids })
      elsif options[:projects].present?
        rel = rel.where(projects: { id: Array(options[:projects]).map(&:id) })
      end

      from, to = options.values_at(:from, :to)
      if from && to
        rel = rel.where(updated_at: from..to)
      elsif from
        rel = rel.where(arel_table[:updated_at].gteq(from))
      elsif to
        rel = rel.where(arel_table[:updated_at].lteq(to))
      end

      rel.order(:wiki_page_id, wiki_version_id: :desc)
    }
end
