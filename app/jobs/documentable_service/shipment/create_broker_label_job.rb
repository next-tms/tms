# frozen_string_literal: true

module DocumentableService
  class Shipment::CreateBrokerLabelJob < ApplicationJob
    queue_as :high_priority

    def perform(shipment)
      items_count = shipment.items.sum(:quantity)
      packaging_label = if Packaging.where(id: shipment.items.pluck(:packaging_id)).pluck(:name).uniq.size == 1
                          shipment.items.first.packaging.name.titleize
                        else
                          'Piece'
                        end
      pro = (shipment.tracking_carrier_pro.presence || shipment.pro)
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

      Prawn::Labels.types = Rails.root.join('config/prawn-label-types.yml').to_s
      Prawn::Labels.generate(file.path, labels, type: 'Avery15264') do |pdf, label|
        pdf.text(label)
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: "#{shipment.load_id} Labels.pdf",
        content_type: 'application/pdf',
      )
      shipment.broker_label.attach(blob)
      shipment.broadcast_new_document_generated(:broker_label)

      file.unlink
    end
  end
end
