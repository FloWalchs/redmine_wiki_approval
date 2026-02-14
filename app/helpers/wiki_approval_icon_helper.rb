module WikiApprovalIconHelper

    def rma_icon(name, text = nil, legacy_text_only: false)
      if respond_to?(:sprite_icon)
        # new redmine versions
        sprite_icon(name, text)
      else
        # Redmine 5.1 or older: CSS-Icon + Text
        return (text || '') if legacy_text_only

        icon_span = content_tag(:span, '', class: "icon icon-#{name}")
        text ? safe_join([icon_span, ' ', text]) : icon_span
      end
    end

end