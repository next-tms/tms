# frozen_string_literal: true

class CreateShipmentBrokerLabelJob < ApplicationJob
  queue_as :high_priority

  def perform(shipment:)
    return unless shipment.can_create_broker_label?

    shipment.broadcast_outdated_document(:broker_label)

    items_count = shipment.items.sum(:quantity)
    packaging_label = if Packaging.where(id: shipment.items.pluck(:packaging_id)).pluck(:name).uniq.size == 1
                        shipment.items.first.packaging.name.titleize
                      else
                        'Piece'
                      end
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

          #{packaging_label} #{i} of #{items_count}
        LABEL

        i += 1
      end
    end

    file = Tempfile.new

    Prawn::Labels.types = File.join(Rails.root, 'config', 'prawn-label-types.yml')
    Prawn::Labels.generate(file.path, labels, type: 'Avery15264') do |pdf, label|
      pdf.text(label)
    end

    result = shipment.broker_label.attach(
      io: file,
      filename: "#{shipment.load_id} Labels.pdf",
      content_type: 'application/pdf'
    )

    Honeybadger.notice("shipment.broker_label.attach didn't return true:\n#{shipment.broker_bol.errors}") unless result

    shipment.broker_label.reload.blob.upload(file)

    shipment.broadcast_new_document_generated(:broker_label)

    file.unlink
  end
end
