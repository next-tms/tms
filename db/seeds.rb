if Carrier.all.size == 0
  Carrier.create name: 'Fake Transportation', scac: 'FAKE'
end

if Broker.all.size == 0
  Broker.create name: 'Fake Broker'
end

if Packaging.all.size == 0
  packaging_names = ['tote', 'crate', 'cylinder', 'drum', 'luggage', 'pail', 'pallet', 'piece', 'roll', 'truckload', 'vehicle']
  packaging_names.each do |packaging_name|
    Packaging.create name: packaging_name
  end
end

if Accessorial.all.size == 0
  limited_access_types = [
    'Airport %word%',
    'Cemetery %word%',
    'Church %word%',
    'Construction or Jobsite %word%',
    'Amusement Park %word%',
    'Farm %word%',
    'Golf Course %word%',
    'Government %word%',
    'Grocery Warehouse %word%',
    'Hospital %word%',
    'Inspection Site %word%',
    'Mall %word%',
    'Marina %word%',
    'Military Site %word%',
    'Mine Site %word%',
    'Storage Facility %word%',
    'Nursing Home %word%',
    'Park %word%',
    'Prison %word%',
    'Ranch %word%',
    'Athletic Facility %word%',
    'Reservation %word%',
    'Lodging %word%',
    'Restaurant %word%',
    'School %word%',
    'Steel Mill %word%',
    'Utility Site %word%',
    'Brewery/Winery %word%',
    'Liftgate %word%',
    'Residential %word%'
  ]
  
  ['Delivery', 'Pickup'].each do |word|
    limited_access_types.each do |limited_access_type|
      Accessorial.find_or_create_by name: limited_access_type.sub('%word%', word)
    end
  end
end

# User roles
role_names = ['dispatch', 'accounting', 'tracking', 'accounts_payable', 'accounts_receivable', 'claims', 'sales_representative_for_all_customers']

role_names.each do |role_name|
  role = Role.find_or_create_by(name: role_name)
end

Broker.find_each do |broker|
  Accessorial.all.each do |accessorial|
    BrokerAccessorial.create(broker: broker, accessorial: accessorial, name: accessorial.name)
  end
end

# Test account setup
if Rails.env == 'development' and User.find_by_email('test@example.com').blank?
  address = Address.create street: '555 Fake St', city: 'Fake', state: 'FA', zip_code: '55555'
  broker = Broker.find_or_create_by name: 'Fake Transport', address: address, phone: '5555555555', customer_service_email: 'cs@faketransport.com'
  broker_carrier = BrokerCarrier.find_or_create_by broker: broker, carrier: Carrier.find_by_scac('FAKE')
  user = User.new
  user.broker = broker
  user.email = 'test@example.com'
  user.password = 'test123'
  user.save!
end