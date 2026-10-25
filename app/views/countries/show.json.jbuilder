json.country do
  json.id @country.alpha2
  json.alpha2 @country.alpha2
  json.name @country.name

  json.regions @regions do |region|
    json.id region.iso31662
    json.abbreviation region.abbreviation
    json.name region.name
  end
end
