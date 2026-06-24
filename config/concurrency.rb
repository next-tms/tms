require 'active_support/core_ext/numeric/bytes'
require 'etc'

module Concurrency
  module_function

  def cpus = Etc.nprocessors
  def max_threads = ENV.fetch('RAILS_MAX_THREADS') { cpus * 2 + 1 }.to_i
  def memory = ENV.fetch('FLY_VM_MEMORY_MB', '1024').to_i.megabytes

  def web_workers
    budget = [ (memory - 512.megabytes) / 384.megabytes, 1 ].max
    ENV.fetch('WEB_CONCURRENCY') { [ cpus, budget ].min }.to_i
  end
end
