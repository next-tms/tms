Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect('ebol' => 'EBOL')
end
