json.broker_carrier_name(@broker_carrier.broker_customer_specific_name)
json.date(@cutoff_date.strftime('%b %e %Y'))
json.payment_transactions_count(@payment_transactions.count)
