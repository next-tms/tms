json.array!(@payment_transactions) { |payment_transaction| json.merge!(payment_transaction.dsdc_invoice) }
