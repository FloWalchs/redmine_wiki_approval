# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start :rails do
    add_filter 'init.rb'
    root File.expand_path "#{File.dirname __FILE__}/.."
  end
end

$VERBOSE = nil if ENV['SUPPRESS_WARNINGS']

# Load the normal Rails helper
require File.expand_path('../../../test/test_helper', __dir__)

PLUGIN_FIXTURES_DIR = File.expand_path('fixtures', __dir__)

module WikiApproval
  module Test
    module PluginTestSetting
      def load_plugin_fixtures_in_order!
        ActiveRecord::FixtureSet.reset_cache
        ActiveRecord::FixtureSet.create_fixtures(
          PLUGIN_FIXTURES_DIR,
          %w[wiki_approval_workflows wiki_approval_workflow_steps wiki_approval_settings]
        )
      end

      def load_default_values!
        @admin = User.find_by(login: 'admin')
        @jsmith = User.find_by(login: 'jsmith')
        @dlopper = User.find_by(login: 'dlopper')
        @rhill = User.find_by(login: 'rhill')
        @manager_role = Role.find_by(name: 'Manager')
        @developer_role = Role.find_by(name: 'Developer')
        [@manager_role, @developer_role].each do |role|
          role.add_permission! :wiki_approval_settings
          role.add_permission! :wiki_approval_start
          role.add_permission! :wiki_approval_grant
          role.add_permission! :wiki_approval_forward
          role.add_permission! :wiki_draft_view
          role.add_permission! :wiki_draft_create
        end
        @project = Project.find 1
        @project3 = Project.find 3
        [@project, @project3].each do |project|
          project.enable_module! :wiki_approval
        end
        @group = Group.first
      end

      def set_session_user(user)
        @user = user
        @request.session[:user_id] = @user.id
        User.current = @user
      end
    end

    class UnitCase < ActiveSupport::TestCase
      include WikiApproval::Test::PluginTestSetting

      def setup
        load_plugin_fixtures_in_order!
        load_default_values!
      end
    end

    class ControllerCase < ActionController::TestCase
      include WikiApproval::Test::PluginTestSetting

      def setup
        load_plugin_fixtures_in_order!
        load_default_values!
      end
    end

    class IntegrationCase < Redmine::IntegrationTest
      include WikiApproval::Test::PluginTestSetting

      def setup
        load_plugin_fixtures_in_order!
        load_default_values!
      end
    end

    class RoutingCase < Redmine::RoutingTest
    end
  end
end
