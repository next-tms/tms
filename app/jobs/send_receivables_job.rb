# frozen_string_literal: true

class SendReceivablesJob < ApplicationJob
  def perform
    broker_customers = BrokerCustomer.distinct.where(id: Receivable.unsent.joins(:shipment).pluck(:broker_customer_id))
    order = :created_at

    broker_customers.where.not(receivables_schedule: 'immediately').find_each do |broker_customer|
      receivables = broker_customer.receivables.unpaid.unsent.with_attached_invoice.order(order)
      sendable_receivable_ids = []

      pdf = CombinePDF.new
      load_ids = []

      receivables.each do |receivable|
        next unless receivable.sendable?

        load_ids << receivable.shipment.load_id
        sendable_receivable_ids << receivable.id

        pdf << CombinePDF.parse(receivable.invoice.download)

        if broker_customer.requires_carrier_bol_on_receivables?
          if receivable.shipment.carrier_bol.content_type == 'application/pdf'
            pdf << CombinePDF.parse(receivable.shipment.carrier_bol.download)
          else
            data = receivable.shipment.carrier_bol.download

            Dir.mktmpdir do |dir|
              extension = MimeMagic.new(content_type).extensions&.first
              path = File.join(dir, "#{DateTime.current.to_i}.#{extension}")

              f = File.new(path, 'wb')
              f.write(data)
              f.close

              new_pdf = ImageProcessing::MiniMagick
                        .source(path)
                        .convert('pdf')
                        .call
                        .read

              pdf << CombinePDF.parse(new_pdf)
            end
          end
        end

        if broker_customer.requires_carrier_pod_on_receivables?
          if receivable.shipment.carrier_pod.content_type == 'application/pdf'
            pdf << CombinePDF.parse(receivable.shipment.carrier_pod.download)
          else
            data = receivable.shipment.carrier_pod.download

            Dir.mktmpdir do |dir|
              extension = MimeMagic.new(content_type).extensions&.first
              path = File.join(dir, "#{DateTime.current.to_i}.#{extension}")

              f = File.new(path, 'wb')
              f.write(data)
              f.close

              new_pdf = ImageProcessing::MiniMagick
                        .source(path)
                        .convert('pdf')
                        .call
                        .read

              pdf << CombinePDF.parse(new_pdf)
            end
          end
        end
      end

      next if sendable_receivable_ids.blank?

      pdf_filename = "Batch Invoices - #{broker_customer.customer.name}.pdf"
      pdf_filename = ActiveStorage::Filename.new(pdf_filename).sanitized

      receivables = Receivable.where(id: sendable_receivable_ids).order(order)

      # Using deliver_now because PDF may not persist
      next unless ReceivablesMailer.batch(broker_customer:, load_ids:, pdf:, pdf_filename:).deliver_now

      receivables.update_all(sent_at: DateTime.current)
    end

    broker_customers.where(receivables_schedule: 'immediately').find_each do |broker_customer|
      receivables = broker_customer.receivables.unsent.with_attached_invoice.order(order)

      receivables.each do |receivable|
        next unless receivable.sendable?

        pdf = CombinePDF.new

        if receivable.invoice.content_type == 'application/pdf'
          pdf << CombinePDF.parse(receivable.invoice.download)
        else
          receivable.invoice.open do |f|
            new_pdf = ImageProcessing::MiniMagick
                      .source(f)
                      .convert('pdf')
                      .call
            pdf << CombinePDF.parse(new_pdf)
          end
        end

        if broker_customer.requires_carrier_bol_on_receivables?
          if receivable.shipment.carrier_bol.content_type == 'application/pdf'
            pdf << CombinePDF.parse(receivable.shipment.carrier_bol.download)
          else
            data = receivable.shipment.carrier_bol.download

            Dir.mktmpdir do |dir|
              extension = MimeMagic.new(content_type).extensions&.first
              path = File.join(dir, "#{DateTime.current.to_i}.#{extension}")

              f = File.new(path, 'wb')
              f.write(data)
              f.close

              new_pdf = ImageProcessing::MiniMagick
                        .source(path)
                        .convert('pdf')
                        .call
                        .read

              pdf << CombinePDF.parse(new_pdf)
            end
          end
        end

        if broker_customer.requires_carrier_pod_on_receivables?
          if receivable.shipment.carrier_pod.content_type == 'application/pdf'
            pdf << CombinePDF.parse(receivable.shipment.carrier_pod.download)
          else
            data = receivable.shipment.carrier_pod.download

            Dir.mktmpdir do |dir|
              extension = MimeMagic.new(content_type).extensions&.first
              path = File.join(dir, "#{DateTime.current.to_i}.#{extension}")

              f = File.new(path, 'wb')
              f.write(data)
              f.close

              new_pdf = ImageProcessing::MiniMagick
                        .source(path)
                        .convert('pdf')
                        .call
                        .read
            end

            pdf << CombinePDF.parse(new_pdf)
          end
        end

        pdf_filename = "#{receivable.shipment.load_id} Invoice.pdf"
        pdf_filename = ActiveStorage::Filename.new(pdf_filename).sanitized

        # Using deliver_now because PDF may not persist
        next unless ReceivablesMailer.batch(
          broker_customer:,
          load_ids: [receivable.shipment.load_id],
          pdf:,
          pdf_filename:
        ).deliver_now

        receivable.update_columns(sent_at: DateTime.current)
      end
    end
  end
end
