# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  match "projects/:project_id/wiki_approval_settings", to: "wiki_approval_settings#update", via: [:patch, :post], as: "wiki_approval_settings"
  match "projects/:project_id/wiki_approval/:title/:version", to: "wiki_approval#start_approval", via: [:get, :post], as: "wiki_approval_start"
  match 'projects/:project_id/wiki_approval/:title/:version/grant/:step_id', to: 'wiki_approval#grant_approval', via: [:get, :post],  as: 'wiki_approval_grant'
  match 'projects/:project_id/wiki_approval/:title/:version/forward/:step_id', to: 'wiki_approval#forward_approval', via: [:get, :post],  as: 'wiki_approval_forward'
end
