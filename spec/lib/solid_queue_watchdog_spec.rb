require 'rails_helper'

RSpec.describe(SolidQueueWatchdog) do
  subject(:watchdog) { described_class.new(supervisor) }

  let(:supervisor) { instance_double(SolidQueue::Supervisor, process_id: supervisor_process.id) }
  let(:supervisor_heartbeat_at) { Time.current }
  let!(:supervisor_process) { register('Supervisor(fork)', last_heartbeat_at: supervisor_heartbeat_at) }
  let(:worker_heartbeat_at) { Time.current }

  before do
    Timecop.freeze
    register('Worker', last_heartbeat_at: worker_heartbeat_at, supervisor: supervisor_process)
  end

  after { Timecop.return }

  def register(kind, **attributes)
    SolidQueue::Process.create!(hostname: 'worker', kind:, name: "#{kind}-#{SecureRandom.hex(4)}", pid: 1, **attributes)
  end

  describe '#check' do
    let(:elapsed) { 1.minute }

    before do
      allow(Process).to(receive(:kill))
      watchdog
      Timecop.freeze(elapsed.from_now)
      watchdog.check
    end

    context 'when healthy' do
      let(:supervisor_heartbeat_at) { 10.minutes.from_now }
      let(:elapsed) { 10.minutes }
      let(:worker_heartbeat_at) { 10.minutes.from_now }

      it { expect(Process).not_to(have_received(:kill)) }
      it { expect(watchdog.last_healthy_at).to(eq(Time.current)) }
    end

    context 'when unhealthy past the alive threshold' do
      let(:elapsed) { 5.minutes }

      it { expect(Process).to(have_received(:kill).with(:KILL, Process.pid)) }
    end

    context 'when unhealthy within the alive threshold' do
      let(:worker_heartbeat_at) { 5.minutes.ago }

      it { expect(Process).not_to(have_received(:kill)) }
      it { expect(watchdog.last_healthy_at).to(eq(1.minute.ago)) }
    end
  end

  describe '#healthy?' do
    subject { watchdog.healthy? }

    it { is_expected.to(be(true)) }

    context 'when a kind has only stale heartbeats' do
      let(:worker_heartbeat_at) { 5.minutes.ago }

      it { is_expected.to(be(false)) }
    end

    context 'when a stale process was replaced' do
      let(:worker_heartbeat_at) { 5.minutes.ago }

      before { register('Worker', last_heartbeat_at: Time.current, supervisor: supervisor_process) }

      it { is_expected.to(be(true)) }
    end

    context 'when only the supervisor is registered' do
      before { SolidQueue::Process.where(kind: 'Worker').delete_all }

      it { is_expected.to(be(false)) }
    end

    context 'when the database is unreachable' do
      before { allow(SolidQueue::Process).to(receive(:where).and_raise(ActiveRecord::ConnectionNotEstablished)) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#processes' do
    subject { watchdog.processes }

    let!(:other_supervisor) { register('Supervisor(fork)', last_heartbeat_at: Time.current) }

    before { register('Worker', last_heartbeat_at: Time.current, supervisor: other_supervisor) }

    it { is_expected.to(include(supervisor_process)) }
    it { is_expected.not_to(include(other_supervisor)) }
    it { expect(watchdog.processes.count).to(eq(2)) }
  end

  describe '#stalled?' do
    subject { watchdog.stalled? }

    before do
      watchdog
      Timecop.freeze(elapsed.from_now)
    end

    context 'when the last healthy check is older than the alive threshold' do
      let(:elapsed) { 5.minutes }

      it { is_expected.to(be(true)) }
    end

    context 'when the last healthy check is within the alive threshold' do
      let(:elapsed) { 4.minutes }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#start' do
    before do
      allow(Concurrent::TimerTask).to(receive(:execute))
      watchdog.start
    end

    it { expect(Concurrent::TimerTask).to(have_received(:execute).with(execution_interval: 60.seconds)) }
  end
end
