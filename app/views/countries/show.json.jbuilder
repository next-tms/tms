json.country do
  json.id @country.alpha2
  json.alpha2 @country.alpha2
  json.name @country.name
  json.postal_code @country.postal_code
  json.postal_code_format @country.postal_code_format
  json.postal_code_label @country.postal_code_label

  json.regions @regions do |region|
    json.id region.iso31662
    json.abbreviation region.abbreviation
    json.name region.name
  end
end
