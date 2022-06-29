# Use to generate factory_bot for a existing model e.g
# bundle exec rake create_factory_bot table=User

# add force=true if you want to override an existing factory_bot e.g
# bundle exec rake create_factory_bot table=User force=true

task :create_factory_bot, [:table] => [:environment] do |task, args|
  @columns_to_ignore  = %w[id created_at update_at]
  klass = ENV['table'].singularize.camelcase.constantize

  puts '-------------'
  puts "------------- Generating Factory bot File for #{klass.to_s} Model -------------"
  puts '-------------'

  command = "rails g factory_bot:model #{klass.to_s} #{klass.columns.reject do |c|
    (@columns_to_ignore || []).include?(c.name)
  end.map do |d|
    "#{d.name}:#{d.sql_type == 'jsonb' ? 'json' : d.type}"
  end.join(' ')}"

  command << ' --force' if ENV['force']
  puts command
  puts %x{#{command}}

  puts '------------- END -------------'
end