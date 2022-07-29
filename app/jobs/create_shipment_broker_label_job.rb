# frozen_string_literal: true

class CreateShipmentBrokerLabelJob < ApplicationJob
  queue_as :high_priority

  def perform(shipment:)
    items_count = shipment.items.sum(:quantity)
    pro = shipment.tracking_carrier_pro.present? ? shipment.tracking_carrier_pro : shipment.pro
    pro = if pro.blank?
            "\n"
          else
            "Pro: #{pro}"
          end

    labels = []
    i = 1

    shipment.items.each do |item|
      item.quantity.times do
        labels << <<~LABEL
          Shipper:
          #{shipment.shipper_name}
          #{shipment.shipper_address.pretty("\n")}

          Consignee:
          #{shipment.receiver_name}
          #{shipment.receiver_address.pretty("\n")}

          #{pro}

          Piece #{i} of #{items_count}
        LABEL
      end
    end

    file = Tempfile.new

    Prawn::Labels.types = File.join(Rails.root, 'config', 'prawn-label-types.yml')
    Prawn::Labels.generate(file.path, labels, type: 'Avery15264') do |pdf, label|
      pdf.text(label)
    end

    shipment.broker_label.attach(
      io: file.read,
      filename: "#{shipment.load_id} Labels.pdf",
      content_type: 'application/pdf'
    )

    file.unlink
  end
end
