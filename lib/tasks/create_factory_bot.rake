# Use to generate factory_bot for a existing model e.g
# bundle exec rake create_factory_bot table=User

# add force=true if you want to override an existing factory_bot e.g
# bundle exec rake create_factory_bot table=User force=true

desc 'Generate a factory_bot file for an existing model, e.g. rake create_factory_bot table=User'
task :create_factory_bot, [:table] => [:environment] do |_task, _args|
  @columns_to_ignore = ['id', 'created_at', 'update_at']
  klass = ENV['table'].singularize.camelcase.constantize

  puts '-------------'
  puts "------------- Generating Factory bot File for #{klass} Model -------------"
  puts '-------------'

  attributes = klass.columns
                    .reject { |column| @columns_to_ignore.include?(column.name) }
                    .map { |column| "#{column.name}:#{column.sql_type == 'jsonb' ? 'json' : column.type}" }

  command = "rails g factory_bot:model #{klass} #{attributes.join(' ')}"

  command << ' --force' if ENV['force']
  puts command
  puts `#{command}`

  puts '------------- END -------------'
end
