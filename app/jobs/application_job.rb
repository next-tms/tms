class ApplicationJob < ActiveJob::Base
  retry_on ActiveJob::DeserializationError, wait: 45.seconds, attempts: 5
  # https://edgeapi.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
  # It looks like the attempts count includes the first non-error run, the total number of times job will be run,
  # including the very first one before any “retries”! So attempts 1 means “never retry” and does nothing
end
