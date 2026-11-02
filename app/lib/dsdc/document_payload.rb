class DSDC::DocumentPayload
  CONTENT_TYPES = { 'application/pdf' => 'pdf', 'image/jpeg' => 'jpg', 'image/png' => 'png', 'image/tiff' => 'tif' }.freeze
  MAX_FILE_SIZE = 25.megabytes
  TYPES = [
    'BOL',
    'CAT',
    'COMM',
    'CON',
    'DIM',
    'DIS',
    'DTR',
    'FRB',
    'FUEL',
    'IMG',
    'INSP',
    'INV',
    'LOA',
    'LPR',
    'MSDS',
    'OTHER',
    'PAC',
    'POD',
    'QUO',
    'RESI',
    'RULE',
    'SCL',
    'SPEC',
    'STB',
    'W&I'
  ].freeze

  attr_reader :params

  def initialize(body) = @params = ActionController::Parameters.new(body)

  def attachables
    params.expect(:DOT, :invoiceDate, :MC, :shipmentID)

    params.expect(documents: [[:documentType, { files: [] }]]).flat_map do |document|
      document_type = document.expect(:documentType)
      raise ArgumentError, document_type if TYPES.exclude?(document_type)

      document.expect(files: []).map.with_index(1) { |file, index| attachable(file, document_type, index) }
    end
  end

  def invoice_number = params.expect(:invoiceNumber)
  def unique_id = params.expect(:uniqueID)

  private

  def attachable(file, document_type, index)
    data = Base64.strict_decode64(file)
    raise ArgumentError, 'file too large' if data.bytesize > MAX_FILE_SIZE

    content_type = Marcel::MimeType.for(StringIO.new(data))
    raise ArgumentError, content_type unless CONTENT_TYPES.key?(content_type)

    {
      content_type:,
      filename: "#{invoice_number}-#{document_type.parameterize}-#{index}.#{CONTENT_TYPES[content_type]}",
      io: StringIO.new(data),
      metadata: { document_type: }
    }
  end
end
