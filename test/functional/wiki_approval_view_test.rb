# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class WikiApprovalViewTest < WikiApproval::Test::ControllerCase
  tests WikiController

  def setup
    super
    @page = WikiPage.find(11)
    set_session_user(@jsmith)
  end

  test 'wiki page redirect to released version' do
    get :show, params: { project_id: @project.id, id: @page.title }

    assert_response :redirect
    assert_redirected_to "/projects/1/wiki/#{@page.title}/2"
  end

  test 'wiki page show released version' do
    get :show, params: { project_id: @project.id, id: @page.title, version: 2 }
    assert_response :success
    # link to draft version, under contextual
    assert_select 'div#content div.contextual a.icon.icon-workflows[href*="wiki/Page_with_sections/3"]'
    # closed badge
    assert_select 'div#content div.contextual span.badge.badge-status-closed'
  end

  test 'wiki page show pending version and sidebar' do
    get :show, params: { project_id: @project.id, id: @page.title, version: 3 }
    assert_response :success
    # link to draft version, under contextual
    assert_select 'div#content div.contextual a.icon.icon-workflows[href*="wiki/Page_with_sections/2"]'
    # open badge
    assert_select 'div#content div.contextual span.badge.badge-status-open'
    # workflow approval icon
    assert_select 'div#content div.contextual a.icon.icon-workflows[href*="wiki_approval/Page_with_sections/3"]'
    # sidebar
    assert_select '#sidebar #approval', minimum: 1
    # no workflow grant icon
    assert_select 'div#content div.contextual a.icon.icon-approval', count: 0
    # no workflow forward icon
    assert_select 'div#content div.contextual a.icon.icon-forward', count: 0
  end

  test 'wiki page show pending version and grant forward' do
    set_session_user(@dlopper)
    get :show, params: { project_id: @project.id, id: @page.title, version: 3 }
    assert_response :success
    # workflow grant icon
    assert_select 'div#content div.contextual a.icon.icon-approval[href*="wiki_approval/Page_with_sections/3/grant/2"]'
    # workflow forward icon
    assert_select 'div#content div.contextual a.icon.icon-forward[href*="wiki_approval/Page_with_sections/3/forward/2"]'
  end
end
