module CarriersHelper
  def address_lines(address) = safe_join(address.pretty("\n").split("\n"), tag.br)

  def carrier_user_status(user)
    return 'Deactivated' if user.deactivated?
    return 'Invited' if user.invitation_pending?

    'Active'
  end
end
