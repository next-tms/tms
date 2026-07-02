module Accounting
  class Address
    include ActiveModel::Model

    attr_accessor :city, :country, :line1, :line2, :postal_code, :region
  end
end
