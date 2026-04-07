class CreateRegions < ActiveRecord::Migration[6.1]
  def up
    create_table :regions do |t|
      t.references :country, null: false, foreign_key: true
      t.string :name, index: true, null: false
      t.string :abbreviation, index: true, null: false

      t.timestamps
    end

    say 'Populate regions'
    countries_and_regions = {
      CA: [
         { AB: 'Alberta' },
         { BC: 'British Columbia' },
         { MB: 'Manitoba' },
         { NB: 'New Brunswick' },
         { NL: 'Newfoundland and Labrador' },
         { NS: 'Nova Scotia' },
         { NT: 'Northwest Territories' },
         { NU: 'Nunavut' },
         { ON: 'Ontario' },
         { PE: 'Prince Edward Island' },
         { QC: 'Quebec' },
         { SK: 'Saskatchewan' },
         { YT: 'Yukon' }
      ],
      US: [
         { AK: 'Alaska' },
         { AL: 'Alabama' },
         { AR: 'Arkansas' },
         { AZ: 'Arizona' },
         { CA: 'California' },
         { CO: 'Colorado' },
         { CT: 'Connecticut' },
         { DC: 'District of Columbia' },
         { DE: 'Delaware' },
         { FL: 'Florida' },
         { GA: 'Georgia' },
         { GU: 'Guam' },
         { HI: 'Hawaii' },
         { IA: 'Iowa' },
         { ID: 'Idaho' },
         { IL: 'Illinois' },
         { IN: 'Indiana' },
         { KS: 'Kansas' },
         { KY: 'Kentucky' },
         { LA: 'Louisiana' },
         { MA: 'Massachusetts' },
         { MD: 'Maryland' },
         { ME: 'Maine' },
         { MI: 'Michigan' },
         { MN: 'Minnesota' },
         { MO: 'Missouri' },
         { MS: 'Mississippi' },
         { MT: 'Montana' },
         { NC: 'North Carolina' },
         { ND: 'North Dakota' },
         { NE: 'Nebraska' },
         { NH: 'New Hampshire' },
         { NJ: 'New Jersey' },
         { NM: 'New Mexico' },
         { NV: 'Nevada' },
         { NY: 'New York' },
         { OH: 'Ohio' },
         { OK: 'Oklahoma' },
         { OR: 'Oregon' },
         { PA: 'Pennsylvania' },
         { PR: 'Puerto Rico' },
         { RI: 'Rhode Island' },
         { SC: 'South Carolina' },
         { SD: 'South Dakota' },
         { TN: 'Tennessee' },
         { TX: 'Texas' },
         { UT: 'Utah' },
         { VA: 'Virginia' },
         { VT: 'Vermont' },
         { WA: 'Washington' },
         { WI: 'Wisconsin' },
         { WV: 'West Virginia' },
         { WY: 'Wyoming' }
      ]
    }

    countries_and_regions.each do |country_and_regions|
      country = Country.find_by_alpha2_code(country_and_regions[0].to_s)
      country_and_regions[1].each do |region|
        Region.create(abbreviation: region.first[0].to_s, country:, name: region.first[1])
      end
    end
  end

  def down
    drop_table :regions
  end
end
