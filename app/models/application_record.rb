# for older redmine 5.1, ApplicationRecord is not available
unless defined?(ApplicationRecord)
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
