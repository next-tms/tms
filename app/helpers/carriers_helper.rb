module CarriersHelper
  def address_lines(address) = safe_join(address.pretty("\n").split("\n"), tag.br)
end
