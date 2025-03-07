# frozen_string_literal: true

class BuildAssumedAccesorialsService
  delegate(
    *%i[
       receiver_address
       receiver_name
       shipper_address
       shipper_name
       items
       bol_notes
     ],
    to: :shipment,
  )

  attr_reader :shipment

  def initialize(shipment:)
    @shipment = shipment
  end

  # Collect Shipment Accessorials base from shipper and receiver details
  # Codes for both shipper and receiver details are the same but will differ in the
  # Prefix e.g PAIR for Shipper (P = Pickup) and DAIR for Receiver (D = Delivery)
  def call
    accessorials = []

    receiver_name_parts = receiver_name.split(/\s+/).reject { |part| part.downcase == 'delivery' }

    Accessorial.where.not(freight_kit_code: nil).where('name ILIKE ?', '%delivery').find_each do |accessorial|
      accessorial_name_parts = accessorial.name.split(/\s+/).reject { |part| part.downcase == 'delivery' }
      next unless accessorial_name_parts.intersect?(receiver_name_parts)

      accessorials << accessorial
    end

    shipper_name_parts = shipper_name.split(/\s+/).reject { |part| part.downcase == 'pickup' }

    Accessorial.where.not(freight_kit_code: nil).where('name ILIKE ?', '%pickup').find_each do |accessorial|
      accessorial_name_parts = accessorial.name.split(/\s+/).reject { |part| part.downcase == 'pickup' }
      next unless accessorial_name_parts.intersect?(shipper_name_parts) # Fixed this line

      accessorials << accessorial
    end

    [['D', receiver_name], ['P', shipper_name]].each do |prefix, name|
      if name.present? && ['airport', 'hangar'].any? { |word| name.downcase.include?(word) }
        accessorials << Accessorial.find_by(code: "#{prefix}AIR") # airport
      end
    end

    [['D', receiver_address], ['P', shipper_address]].each do |prefix, address|
      if address.types.present? && address.types.include?('airport')
        accessorials << Accessorial.find_by(code: "#{prefix}AIR")
      end

      if address.types.present? && address.types.include?('military')
        accessorials << Accessorial.find_by(code: "#{prefix}MIL")
      end

      # Residential
      if address.residential? || shipment.accessorial_codes.include?("#{prefix}RES")
        accessorials << Accessorial.find_by(code: "#{prefix}RES")
        accessorials << Accessorial.find_by(code: "#{prefix}APP")
        if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
          accessorials << Accessorial.find_by(code: "#{prefix}LIF")
        end
      end

      # Restaurant
      accessorials << Accessorial.find_by(code: "#{prefix}RST") if address.restaurant?
    end

    # Appointment delivery
    if bol_notes.present? && bol_notes.downcase.include?('must contact')
      accessorials << Accessorial.find_by(code: 'DAPP')
    end

    accessorials.uniq
  end
end
