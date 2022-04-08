# frozen_string_literal: true

def load_yaml(table)
  YAML.safe_load(
    File.open(
      File.join(
        Rails.root,
        'db',
        'seed',
        "#{table}.yaml"
      )
    ),
    permitted_classes: [NilClass, Symbol]
  )&.with_indifferent_access&.dig(table)
end

def import_seeds(tables)
  tables.each do |table|
    model = table.dig(:name).camelize.singularize.constantize
    entries = load_yaml(table.dig(:name))
    entries.each do |entry|
      key = table.dig(:key).to_sym
      val = entry[key]

      database_entry = model.where(Hash[key, val])&.first
      database_entry = model.new(entry) if database_entry.nil?

      database_entry.assign_attributes(entry)
      if database_entry.save
        puts "[  OK  ] Save `#{model.name} id=#{database_entry.id} #{key.to_s}=#{val}`"
      else
        str = "[ FAIL ] Save `#{model.name} id=nil #{key.to_s}=#{val}`".dup
        str << "\n#{database_entry.errors.full_messages.join("\n")}"
        raise str
      end
    end
  end
end

# main

import_seeds(
  [
    { name: 'events', key: :active_shipping_code },
    { name: 'packagings', key: :name },
    { name: 'problem_types', key: :code }
  ]
)
