# frozen_string_literal: true

module WikiApprovalSettingsHelper
  PROJECT = 'project'

  def wiki_approval_select_options
    options = [
      [:general_text_Yes, 'true'],
      [:general_text_No, 'false'],
      [:label_wiki_approval_settings_projects, PROJECT]
    ]

    options.map {|label, value| [l(label), value.to_s]}
  end
end
