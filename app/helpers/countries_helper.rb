module CountriesHelper
  # Select options for countries, with the saved country first when it is not in the list (e.g. Transponder no longer returns it)
  def country_options(countries, saved_alpha2)
    countries = countries.to_a

    if saved_alpha2.present? && countries.none? { |country| country.alpha2 == saved_alpha2 }
      countries.unshift(Transponder::ORM::Country.find_or_initialize_by(alpha2: saved_alpha2))
    end

    countries.map { |country| [country.name, country.alpha2] }
  end
end
