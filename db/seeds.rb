def load_yaml(table)
  YAML.safe_load(
    File.open(
      Rails.root.join('db', 'seed', "#{table}.yaml")
    ),
    permitted_classes: [ NilClass, Symbol ]
  )&.with_indifferent_access&.dig(table)
end

def import_seeds(tables)
  tables.each do |table|
    model = table.dig(:name).camelize.singularize.constantize
    entries = load_yaml(table.dig(:name))
    entries.each do |entry|
      key = table.dig(:key).to_sym
      val = entry[key]

      database_entry = model.where(Hash[key, val])&.first
      database_entry = model.new(entry) if database_entry.nil?

      database_entry.assign_attributes(entry)
      if database_entry.save
        puts "[  OK  ] Save `#{model.name} id=#{database_entry.id} #{key}=#{val}`"
      else
        str = "[ FAIL ] Save `#{model.name} id=nil #{key}=#{val}`".dup
        str << "\n#{database_entry.errors.full_messages.join("\n")}"
        raise str
      end
    end
  end
end

# main

import_seeds(
  [
    { name: 'events', key: :active_shipping_code },
    { name: 'packagings', key: :name },
    { name: 'settings', key: :key }
  ]
)

COUNTRIES_AND_REGIONS = {
  'CA' => {
    alpha3_code: 'CAN',
    un_code: 124,
    name: 'Canada',
    regions: {
      'AB' => 'Alberta',
      'BC' => 'British Columbia',
      'MB' => 'Manitoba',
      'NB' => 'New Brunswick',
      'NL' => 'Newfoundland and Labrador',
      'NT' => 'Northwest Territories',
      'NS' => 'Nova Scotia',
      'NU' => 'Nunavut',
      'ON' => 'Ontario',
      'PE' => 'Prince Edward Island',
      'QC' => 'Quebec',
      'SK' => 'Saskatchewan',
      'YT' => 'Yukon'
    }
  },
  'MX' => {
    alpha3_code: 'MEX',
    un_code: 484,
    name: 'Mexico',
    regions: {
      'AGU' => 'Aguascalientes',
      'BCN' => 'Baja California',
      'BCS' => 'Baja California Sur',
      'CAM' => 'Campeche',
      'CHP' => 'Chiapas',
      'CHH' => 'Chihuahua',
      'CMX' => 'Ciudad de México',
      'COA' => 'Coahuila',
      'COL' => 'Colima',
      'DUR' => 'Durango',
      'GUA' => 'Guanajuato',
      'GRO' => 'Guerrero',
      'HID' => 'Hidalgo',
      'JAL' => 'Jalisco',
      'MEX' => 'México',
      'MIC' => 'Michoacán',
      'MOR' => 'Morelos',
      'NAY' => 'Nayarit',
      'NLE' => 'Nuevo León',
      'OAX' => 'Oaxaca',
      'PUE' => 'Puebla',
      'QUE' => 'Querétaro',
      'ROO' => 'Quintana Roo',
      'SLP' => 'San Luis Potosí',
      'SIN' => 'Sinaloa',
      'SON' => 'Sonora',
      'TAB' => 'Tabasco',
      'TAM' => 'Tamaulipas',
      'TLA' => 'Tlaxcala',
      'VER' => 'Veracruz',
      'YUC' => 'Yucatán',
      'ZAC' => 'Zacatecas'
    }
  },
  'US' => {
    alpha3_code: 'USA',
    un_code: 840,
    name: 'United States of America',
    regions: {
      'AL' => 'Alabama',
      'AK' => 'Alaska',
      'AS' => 'American Samoa',
      'AZ' => 'Arizona',
      'AR' => 'Arkansas',
      'CA' => 'California',
      'CO' => 'Colorado',
      'CT' => 'Connecticut',
      'DE' => 'Delaware',
      'DC' => 'District of Columbia',
      'FL' => 'Florida',
      'GA' => 'Georgia',
      'GU' => 'Guam',
      'HI' => 'Hawaii',
      'ID' => 'Idaho',
      'IL' => 'Illinois',
      'IN' => 'Indiana',
      'IA' => 'Iowa',
      'KS' => 'Kansas',
      'KY' => 'Kentucky',
      'LA' => 'Louisiana',
      'ME' => 'Maine',
      'MD' => 'Maryland',
      'MA' => 'Massachusetts',
      'MI' => 'Michigan',
      'MN' => 'Minnesota',
      'MS' => 'Mississippi',
      'MO' => 'Missouri',
      'MT' => 'Montana',
      'NE' => 'Nebraska',
      'NV' => 'Nevada',
      'NH' => 'New Hampshire',
      'NJ' => 'New Jersey',
      'NM' => 'New Mexico',
      'NY' => 'New York',
      'NC' => 'North Carolina',
      'ND' => 'North Dakota',
      'MP' => 'Northern Mariana Islands',
      'OH' => 'Ohio',
      'OK' => 'Oklahoma',
      'OR' => 'Oregon',
      'PA' => 'Pennsylvania',
      'PR' => 'Puerto Rico',
      'RI' => 'Rhode Island',
      'SC' => 'South Carolina',
      'SD' => 'South Dakota',
      'TN' => 'Tennessee',
      'TX' => 'Texas',
      'UM' => 'United States Minor Outlying Islands',
      'VI' => 'United States Virgin Islands',
      'UT' => 'Utah',
      'VT' => 'Vermont',
      'VA' => 'Virginia',
      'WA' => 'Washington',
      'WV' => 'West Virginia',
      'WI' => 'Wisconsin',
      'WY' => 'Wyoming'
    }
  }
}.freeze

COUNTRIES_AND_REGIONS.each do |alpha2, data|
  country = Country
            .find_or_create_by!(alpha2_code: alpha2) do |country|
              country.alpha3_code = data[:alpha3_code]
              country.un_code = data[:un_code]
              country.name = data[:name]
            end
  puts "[  OK  ] Save `Country id=#{country.id} alpha2_code=#{alpha2}`"

  data[:regions].each do |abbr, name|
    region = Region
             .find_or_create_by!(country:, abbreviation: abbr) do |region|
               region.iso31662 = "#{alpha2}_#{abbr}"
               region.name = name
             end
    puts "[  OK  ] Save `Region id=#{region.id} iso31662=#{region.iso31662}`"
  end
end
