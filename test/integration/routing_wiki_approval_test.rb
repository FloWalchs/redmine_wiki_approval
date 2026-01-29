# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class RoutingWikiTest < Redmine::RoutingTest
  def test_approval
    # Settings
    should_route 'PATCH /projects/foo/wiki_approval_settings' => 'wiki_approval_settings#update',
                 :project_id => 'foo'
    should_route 'POST /projects/foo/wiki_approval_settings'  => 'wiki_approval_settings#update',
                 :project_id => 'foo'

    # Start approval
    should_route 'GET  /projects/foo/wiki_approval/Page_with_sections/3' => 'wiki_approval#start_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3'
    should_route 'POST /projects/foo/wiki_approval/Page_with_sections/3' => 'wiki_approval#start_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3'

    # Grant
    should_route 'GET  /projects/foo/wiki_approval/Page_with_sections/3/grant/7' => 'wiki_approval#grant_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3', :step_id => '7'
    should_route 'POST /projects/foo/wiki_approval/Page_with_sections/3/grant/7' => 'wiki_approval#grant_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3', :step_id => '7'

    # Forward
    should_route 'GET  /projects/foo/wiki_approval/Page_with_sections/3/forward/7' => 'wiki_approval#forward_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3', :step_id => '7'
    should_route 'POST /projects/foo/wiki_approval/Page_with_sections/3/forward/7' => 'wiki_approval#forward_approval',
                 :project_id => 'foo', :title => 'Page_with_sections', :version => '3', :step_id => '7'
  end
end
