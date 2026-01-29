# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WikiApprovalSettingsControllerTest < WikiApproval::Test::ControllerCase
  tests WikiApprovalSettingsController

  def setup
    super
    set_session_user(@admin)
  end

  test "save additional settings fields" do
    # Plugin-Settings to 'project'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = WikiApprovalSettingsHelper::PROJECT
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = WikiApprovalSettingsHelper::PROJECT
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_enabled] = WikiApprovalSettingsHelper::PROJECT
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = WikiApprovalSettingsHelper::PROJECT
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_version] = WikiApprovalSettingsHelper::PROJECT

    post :update, params: {
      project_id: @project.id,
      wiki_comment_required: 'true',
      wiki_draft_enabled: 'false',
      wiki_approval_enabled: 'true',
      wiki_approval_required: 'false',
      wiki_approval_version: 'true'
    }

    assert_response :redirect
    setting = WikiApprovalSetting.find(@project.id)
    setting.reload

    assert setting.wiki_comment_required
    assert_not setting.wiki_draft_enabled
    assert setting.wiki_approval_enabled
    assert_not setting.wiki_approval_required
    assert setting.wiki_approval_version
  end
end
