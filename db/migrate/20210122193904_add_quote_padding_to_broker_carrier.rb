class AddQuotePaddingToBrokerCarrier < ActiveRecord::Migration[6.0]
  def change
    add_monetize :broker_carriers, :quote_padding
  end
end
