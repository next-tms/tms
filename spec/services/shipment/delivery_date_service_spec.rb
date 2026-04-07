# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::DeliveryDateService) do
  let!(:shipment) { create(:shipment) }

  before { Timecop.freeze(Time.zone.now) }
  after { Timecop.return }

  shared_examples_for 'shipment delivery date' do
    context 'when receiver_address is blank' do
      before { shipment.update(receiver_address: nil) }

      it { is_expected.to(be_nil) }
    end

    context 'when receiver_address#time_zone is blank' do
      before { allow_any_instance_of(Address).to(receive(:time_zone).and_return(nil)) }

      it { is_expected.to(be_nil) }
    end

    %i[promised_delivery_by delivery_appointment_at].each do |shipment_datetime|
      context "when #{shipment_datetime} is present" do
        let(:nullable_dates) do
          dates = %i[
                    promised_delivery_by
                    delivery_appointment_at
                    delivery_appointment_on
                    delivery_eta_on
                  ] - [ shipment_datetime ]
          dates.map { |date| { date => nil } }.reduce({}, :merge)
        end

        before do
          shipment.update!(shipment_datetime => Time.zone.now.change(nsec: 0))
          shipment.update!(**nullable_dates)
        end

        it { is_expected.to(eq(shipment.reload.send(shipment_datetime))) }
      end
    end

    %i[delivery_appointment_on delivery_eta_on].each do |shipment_date|
      context "when #{shipment_date} is present" do
        let(:nullable_dates) do
          dates = %i[
                    promised_delivery_by
                    delivery_appointment_at
                    delivery_appointment_on
                    delivery_eta_on
                  ] - [ shipment_date ]
          dates.map { |date| { date => nil } }.reduce({}, :merge)
        end

        before do
          shipment.update!(shipment_date => Time.zone.now.change(nsec: 0))
          shipment.update!(**nullable_dates)
        end

        context 'when delivery hours is present' do
          it "returns ##{shipment_date} converted to datetime based on receiver address timezone" do
            timezone = shipment.receiver_address.time_zone
            formatted_offset = Time.current.in_time_zone(timezone).formatted_offset
            expected_datetime = Time.zone.parse("#{shipment.send(shipment_date)} #{delivery_hours} #{formatted_offset}")
            expect(subject).to(eq(expected_datetime))
          end
        end

        context 'when delivery hours is null' do
          before { shipment.update(delivery_hours_end_at: nil, delivery_hours_start_at: nil) }

          it 'returns converted datetime with interval' do
            timezone = shipment.receiver_address.time_zone
            expect(subject).to(eq(shipment.send(shipment_date).in_time_zone(timezone).beginning_of_day + hours_interval))
          end
        end
      end

      context 'when dates are null' do
        before { shipment.update(promised_delivery_by: nil, delivery_appointment_at: nil, delivery_appointment_on: nil, delivery_eta_on: nil) }

        context 'when pickup date is null' do
          before { allow(shipment).to(receive(pickup_date_attr).and_return(nil)) }

          it { is_expected.to(be_nil) }
        end

        context 'when pickup dates are present' do
          before { allow(shipment).to(receive(pickup_date_attr).twice.and_return(Time.zone.now.change(nsec: 0))) }

          it 'returns pickup date + 5 business days with interval' do
            timezone = shipment.receiver_address.time_zone
            expected_datetime = 5.business_days.after(shipment.send(pickup_date_attr).in_time_zone(timezone)).beginning_of_day + hours_interval
            expect(subject).to(eq(expected_datetime))
          end
        end
      end
    end
  end

  describe '#delivery_from' do
    subject { described_class.new(shipment:).delivery_from }

    let(:delivery_hours) { shipment.delivery_hours_start_at }
    let(:hours_interval) { 9.hours }
    let(:pickup_date_attr) { :pickup_from }

    it_behaves_like 'shipment delivery date'
  end

  describe '#delivery_by' do
    subject { described_class.new(shipment:).delivery_by }

    let(:delivery_hours) { shipment.delivery_hours_end_at }
    let(:hours_interval) { 17.hours }
    let(:pickup_date_attr) { :pickup_by }

    it_behaves_like 'shipment delivery date'
  end
end
