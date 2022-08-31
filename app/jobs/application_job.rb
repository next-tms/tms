class ApplicationJob < ActiveJob::Base
  retry_on ActiveJob::DeserializationError, wait: 45.seconds, attempts: 1
  # https://edgeapi.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
end
