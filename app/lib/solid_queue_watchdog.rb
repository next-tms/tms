class SolidQueueWatchdog
  attr_reader :last_healthy_at, :supervisor

  def initialize(supervisor)
    @last_healthy_at = Time.current
    @supervisor = supervisor
  end

  def check
    @last_healthy_at = Time.current if healthy?
    Process.kill(:KILL, Process.pid) if stalled?
  end

  def healthy?
    heartbeats = Rails.application.executor.wrap { processes.group(:kind).maximum(:last_heartbeat_at) }
    heartbeats.size > 1 && heartbeats.values.all? { |last_heartbeat_at| last_heartbeat_at > SolidQueue.process_alive_threshold.ago }
  rescue StandardError
    false
  end

  def processes = SolidQueue::Process.where(id: supervisor.process_id).or(SolidQueue::Process.where(supervisor_id: supervisor.process_id))
  def stalled? = last_healthy_at <= SolidQueue.process_alive_threshold.ago
  def start = Concurrent::TimerTask.execute(execution_interval: SolidQueue.process_heartbeat_interval) { check }
end
