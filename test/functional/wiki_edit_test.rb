# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WikiEditTest < WikiApproval::Test::ControllerCase
  tests WikiController

  def setup
    super
    set_session_user(@jsmith)
    @page = WikiPage.find_by(id: 1)
    @page.content ||= WikiContent.create!(page: @page, text: 'test')
  end

  test "should render wiki edit draft comment" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    # 1. draft checkbox checked and disabled
    assert_select 'input[type=checkbox][name=status][id=status][value=draft][disabled=disabled][checked=checked]'
    # 3. commend required just in javascript
    assert_includes @response.body, 'span.textContent = " *"'

    # update page
    put :update, params: { project_id: @project.id, id: @page.title,
      content: {
        text: 'new text in textarea',
        comments: 'my comment'
      },
      status_disabled: 'true',
      status: 'draft'}

    assert_response :redirect

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    @page.reload

    # draft status in db
    approval = WikiApprovalWorkflow.for_wiki(@page.id, @page.content.version).first
    assert_equal 'draft', approval.status
  end

  test "should render wiki edit with no draft no comment" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    # 1. draft checkbox  disabled=false checked=false
    assert_select 'input[type=checkbox][name=status][id=status][value=draft]' do |elements|
      el = elements.first
      assert_nil el['disabled'], 'not disabled'
      assert_nil el['checked'], 'not checked'
    end

    # 1. find <label>, with "Comment"
    assert_select 'label', text: /Comment/ do |labels|
      labels.each do |label|
        # 2. Label without <span class="required">
        assert_select label, 'span.required', count: 0
      end
    end
  end

  test 'should render wiki edit with draft checked disabled version required' do
    @page = WikiPage.find(11)
    @page.content ||= WikiContent.create!(page: @page, text: 'test')
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_enabled] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_version] = 'true'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    # 1. draft checkbox checked and disabled, because of last version approved
    assert_select 'input[type=checkbox][name=status][id=status][value=draft][disabled=disabled][checked=checked]'
  end

  test 'should render wiki edit with draft checked disabled required' do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_enabled] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_version] = 'false'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    # 1. draft checkbox checked and disabled, because of approval required no draft
    assert_select 'input[type=checkbox][name=status][id=status][value=draft][disabled=disabled][checked=checked]'
  end

  test 'should render wiki edit with draft not checked disabled' do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_enabled] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_version] = 'false'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    # 1. draft checkbox not checked and disabled, because of approval enabled, each version is published
    assert_select 'input[type=checkbox][name=status][id=status][value=draft][disabled=disabled]'
    assert_select 'input[type=checkbox][name=status][id=status][value=draft][checked]', 0
  end

  test 'should render wiki edit with draft not checked disabled only draft' do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_enabled] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'false'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_version] = 'false'

    get :edit, params: { project_id: @project.id, id: @page.title }
    assert_response :success

    assert_select 'input[type=checkbox][name=status][id=status][value=draft]' do |elements|
      el = elements.first
      assert_nil el['disabled'], 'not disabled'
      assert_nil el['checked'], 'not checked'
    end
  end

  test "should not update wiki page comment required" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    # update page
    assert_no_difference 'WikiApprovalWorkflow.count' do
      put :update, params: { project_id: @project.id, id: @page.title,
        content: {
          text: 'new text in textarea',
          comments: ''
        },
        status_disabled: 'true',
        status: 'draft'}
    end

    assert_response :success 
    assert_select "div#errorExplanation"

  end

  test "should not save new wiki page comment required" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    # new page
    assert_no_difference ['WikiPage.count', 'WikiApprovalWorkflow.count'] do
      put :update, params: { project_id: @project.id, id: 'newWikPageApproval',
        content: {
          text: 'new text in textarea',
          comments: ''
        },
        status_disabled: 'true',
        status: 'draft'}
    end

    assert_response :success 
    assert_select "div#errorExplanation"

  end

  test "should update wiki page comment required" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    # update page
    assert_difference 'WikiApprovalWorkflow.count', 1 do
      put :update, params: { project_id: @project.id, id: @page.title,
        content: {
          text: 'new text in textarea',
          comments: 'should update comment'
        },
        status_disabled: 'true',
        status: 'draft'}
    end

    assert_response :redirect 
    assert_select "div#errorExplanation", false

  end

  test "should save new wiki page comment required" do
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_comment] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_required] = 'true'
    Setting.plugin_redmine_wiki_approval[:wiki_approval_settings_draft_enabled] = 'true'

    # new page
    assert_difference ['WikiPage.count', 'WikiApprovalWorkflow.count'] do
      put :update, params: { project_id: @project.id, id: 'newWikPageApproval',
        content: {
          text: 'new text in textarea',
          comments: 'comment new'
        },
        status_disabled: 'true',
        status: 'draft'}
    end

    assert_response :redirect 
    assert_select "div#errorExplanation", false

  end
end