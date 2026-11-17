module EBOL
  class << self
    def accessorial_code(freight_kit_code) = ACCESSORIAL_CODES[freight_kit_code]
    def accessorial_codes(accessorials) = accessorials.filter_map { |accessorial| accessorial_code(accessorial.freight_kit_code) }
    def freight_kit_code(code) = ACCESSORIAL_CODES.key(code)
    def freight_kit_type(type) = HANDLING_UNIT_ALIASES[type.to_s.upcase] || HANDLING_UNIT_TYPES.key(type.to_s.upcase) || 'piece'
    def handling_unit_type(packaging) = HANDLING_UNIT_TYPES.fetch(packaging&.freight_kit_type, 'OTH')
    def valid?(document) = SCHEMA.valid?(document.as_json)

    private

    def defined_requirements(node)
      case node
      when Array then node.map { |element| defined_requirements(element) }
      when Hash
        schema = node.transform_values { |value| defined_requirements(value) }
        schema['properties'] ? schema.merge('required' => schema['required']&.intersection(schema['properties'].keys)).compact : schema
      else node
      end
    end

    def openapi = defined_requirements(YAML.safe_load_file(Rails.root.join("vendor/nmfta/ebol-#{VERSION}.openapi.yaml"), aliases: true))
  end

  ACCESSORIAL_CODES = {
    'appointment_delivery' => 'APTD',
    'appointment_pickup' => 'APTP',
    'guaranteed_delivery_am' => 'GTD_AM',
    'guaranteed_delivery_pm' => 'GTD_PM',
    'inside_delivery' => 'IDL',
    'inside_pickup' => 'IPU',
    'liftgate_delivery' => 'LFTD',
    'liftgate_pickup' => 'LFTP',
    'limited_access_delivery' => 'LTDAD',
    'limited_access_pickup' => 'LTDAP',
    'notify_before_delivery' => 'MNC',
    'residential_delivery' => 'RES',
    'residential_pickup' => 'REP'
  }.freeze
  DELIVERY_ACCESSORIAL_CODES = ACCESSORIAL_CODES.select { |freight_kit_code, _code| freight_kit_code.include?('delivery') }.values.freeze
  HANDLING_UNIT_ALIASES = { 'SKD' => 'pallet' }.freeze
  HANDLING_UNIT_TYPES = {
    'box' => 'BOX',
    'bundle' => 'BDL',
    'container' => 'CNT',
    'crate' => 'CRT',
    'cylinder' => 'CYL',
    'drum' => 'DRM',
    'pail' => 'PAL',
    'pallet' => 'PAT',
    'piece' => 'PCS',
    'roll' => 'ROL',
    'tote' => 'TBN',
    'truckload' => 'TRU'
  }.freeze
  VERSION = '2.1.0'.freeze
  SCHEMA = JSONSchemer.openapi(openapi).schema('BOL_Request')
end
