# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WikiApprovalActivityControllerTest < WikiApproval::Test::ControllerCase
  tests ActivitiesController
  def setup
    super
    set_session_user(@admin)
  end

  test 'activity provider is registered' do
    providers = Redmine::Activity.available_event_types
    assert_includes providers, 'wiki_approval_workflow'
  end

  test 'activity provider 2 entry' do
    get(
      :index,
      :params => {
        :format => 'atom',
        :with_subprojects => 0,
        :show_wiki_approval_workflow => 1
      }
    )
    assert_response :success
    assert_select 'feed' do
      assert_select 'entry', :count => 2
      assert_select 'link[rel=self][href=?]', 'http://test.host/activity.atom?show_wiki_approval_workflow=1&with_subprojects=0'
      assert_select 'link[rel=alternate][href=?]', 'http://test.host/activity?show_wiki_approval_workflow=1&with_subprojects=0'
      assert_select 'entry' do
        assert_select 'link[href=?]', 'http://test.host/projects/ecookbook/wiki/Page_with_sections/3'
        assert_select 'link[href=?]', 'http://test.host/projects/ecookbook/wiki/Page_with_sections/2'
      end
    end
  end

  test 'activity provider with sub projects' do
    subproject = @project3
    # Ensure subproject has a wiki
    subproject.create_wiki(start_page: 'Wiki')
    # Add a wiki page to the subproject and update its content
    @page = WikiPage.create!(wiki: subproject.wiki, title: 'Subproject Page')
    content = WikiContent.create!(page: @page, text: 'content', author_id: 1, updated_on: Time.now)
    WikiApprovalWorkflow.create!(
      wiki_page_id: @page.id,
      wiki_version_id: content.version,
      status: :draft,
      author_id: @user.id
    )

    get(
      :index,
      :params => {
        :format => 'atom',
        :with_subprojects => 1,
        :show_wiki_approval_workflow => 1
      }
    )
    assert_response :success
    assert_select 'feed' do
      assert_select 'entry', :count => 3
      assert_select 'entry' do
        assert_select 'link[href=?]', 'http://test.host/projects/subproject1/wiki/Subproject_Page/1'
        assert_select 'link[href=?]', 'http://test.host/projects/ecookbook/wiki/Page_with_sections/3'
        assert_select 'link[href=?]', 'http://test.host/projects/ecookbook/wiki/Page_with_sections/2'
      end
    end
  end

  test 'activity provider no permission' do
    set_session_user(@admin)
    subproject = @project3
    # Ensure subproject has a wiki
    subproject.create_wiki(start_page: 'Wiki')
    # Add a wiki page to the subproject and update its content
    @page = WikiPage.create!(wiki: subproject.wiki, title: 'Subproject Page')
    content = WikiContent.create!(page: @page, text: 'content', author_id: 1, updated_on: Time.now)
    WikiApprovalWorkflow.create!(
      wiki_page_id: @page.id,
      wiki_version_id: content.version,
      status: :draft,
      author_id: @user.id
    )

    get(
      :index,
      :params => {
        :id => subproject.identifier,
        :format => 'atom',
        :with_subprojects => 0,
        :show_wiki_approval_workflow => 1
      }
    )
    assert_response :success
    assert_select 'link[href=?]', 'http://test.host/projects/subproject1/wiki/Subproject_Page/1'

    # no permission
    set_session_user(@jsmith)
    get(
      :index,
      :params => {
        :id => subproject.identifier,
        :format => 'atom',
        :with_subprojects => 0,
        :show_wiki_approval_workflow => 1
      }
    )
    assert_response :success
    assert_select 'link[href=?]', 'http://test.host/projects/subproject1/wiki/Subproject_Page/1', 0
  end
end
