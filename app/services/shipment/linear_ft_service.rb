class Shipment::LinearFtService
  attr_reader :shipment, :items

  MAX_LENGTH = 102.freeze

  def initialize(shipment:)
    @shipment = shipment
    @items = shipment.items
  end

  def call
    linear_ft = 0
    true_items = []
    item_rows = []

    items.each do |item|
      next unless item.l && item.w && item.h

      item.quantity.times do
        # Rotate the item if longer that 102 inches
        true_items << if item.long_side > MAX_LENGTH
                        { l: item.short_side, w: item.long_side, allocated: false }
                      else
                        { l: item.long_side, w: item.short_side, allocated: false }
                      end
      end
    end

    return if true_items.blank?

    true_items = true_items.sort_by { |k| k[:l] } # Find longest piece first

    i = 0
    row_length = 0
    row_width = 0
    row_tries = 0

    loop do
      items_allocated_count = 0

      true_items.each do |true_item|
        items_allocated_count += 1 if true_item[:allocated]
      end

      if true_items[i].nil?
        i = 0
        redo
      end

      if items_allocated_count == true_items.count
        item_rows << { l: row_length, w: row_width }
        break
      end

      if true_items[i][:allocated]
        i += 1
        redo
      end

      if row_tries > (true_items.count * true_items.count)
        item_rows << { l: row_length, w: row_width }
        row_length = 0
        row_width = 0
        row_tries = 0
        redo
      end

      if true_items[i][:l] <= (MAX_LENGTH - row_length)
        row_length += true_items[i][:l]
        row_width = true_items[i][:w] if true_items[i][:w] > row_width
        true_items[i][:allocated] = true
        i += 1
      elsif true_items[i][:l] > (MAX_LENGTH - row_length)
        i += 1
        row_tries += 1
        redo
      end
    end

    item_rows.each { |item_row| linear_ft += item_row[:w] }

    (linear_ft / 12.to_f).ceil
  end
end
