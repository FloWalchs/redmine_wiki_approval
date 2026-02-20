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
      assert_select 'entry', :count => 5
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
      assert_select 'entry', :count => 6
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

  test 'activity provider should filter by subprojects and date range' do
    set_session_user(@admin)
    
    # 1. Setup: Hauptprojekt und Subprojekt
    project = Project.find(1) # e.g. ecookbook
    subproject = @project3 # e.g. subproject1
    subproject.set_parent!(@project)
    
    # Wiki für Subprojekt sicherstellen
    subproject.create_wiki(start_page: 'SubPage') unless subproject.wiki
    page_sub = WikiPage.create!(wiki: subproject.wiki, title: 'Subproject_Page')
    
    # 2. Daten erstellen mit verschiedenen Zeitstempeln
    time_now = Time.now.utc
    time_old = 1.days.ago.utc
    time_very_old = 30.days.ago.utc

    # Eintrag im Subprojekt (JETZT) -> Sollte erscheinen
    WikiApprovalWorkflow.create!(wiki_page: page_sub, wiki_version_id: 1, status: 10, author_id: @admin.id, created_at: time_now)

    # Eintrag im Hauptprojekt (ALT) -> Sollte durch Zeitfilter fliegen
    page_main = project.wiki.pages.first
    workflow_main = WikiApprovalWorkflow.create!(wiki_page: page_main, wiki_version_id: 2, status: 10, author_id: @admin.id)
    WikiApprovalWorkflowStatus.create!(
      wiki_approval_workflow: workflow_main, 
      status: 20, 
      author_id: 1, 
      created_at: time_very_old
    )

    WikiApprovalWorkflowStatus.create!(
      wiki_approval_workflow: workflow_main, 
      status: 20, 
      author_id: 1, 
      created_at: time_very_old
    )

    # --- TEST 1: Mit Subprojekten und Zeitfilter ---
    get :index, params: {
      id: project.identifier,
      from: time_very_old.to_date.to_s,
      to: time_now.to_date.to_s,
      with_subprojects: 1,
      show_wiki_approval_workflow: 1
    }

    assert_response :success

    assert_select "div#activity" do
      assert_select "dl", count: 1
      assert_select "dl" do
        # Prüft, ob genau 2 <dt> Elemente vorhanden sind
        assert_select "dt", count: 2
        
        # Spezifische Prüfung des ersten (normalen) Eintrags
        assert_select "dt.workflows.icon-workflows" do
          assert_select "a[href=?]", "/projects/ecookbook/wiki/Another_page/2", text: /Another_page \(#2\)/
        end

        # Spezifische Prüfung des gruppierten Eintrags
        assert_select "dt.grouped"

        # Prüft das Vorhandensein des <dd> mit der Klasse 'grouped'
        assert_select "dd.grouped" do
          assert_select "span.description", text: "In approval"
          assert_select "span.author", text: "Redmine Admin"
        end
      end
    end

  end
end
