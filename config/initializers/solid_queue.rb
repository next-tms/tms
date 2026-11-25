SolidQueue.on_start { |supervisor| SolidQueueWatchdog.new(supervisor).start }
