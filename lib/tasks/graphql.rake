require 'json'

dsl_path  = Settings.graphql.schema.dsl
json_path = Settings.graphql.schema.json
docs_path = Settings.graphql.docs.output

namespace :graphql do
  namespace :dump do
    desc "Dumps the IDL schema into #{dsl_path} file"
    task idl: [:environment] do
      target = Rails.root.join(dsl_path)
      schema = GraphQL::Schema::Printer.print_schema(Schema)
      File.open(target, 'w+') do |f|
        f.write(schema)
      end
      puts "Schema dumped into #{dsl_path}"
    end

    desc "Dumps the result of the introspection query into #{json_path} file"
    task json: [:environment] do
      target = Rails.root.join(json_path)
      result = Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      File.open(target, 'w+') do |f|
        f.write(JSON.pretty_generate(result))
      end
      puts "Schema dumped into #{json_path}"
    end
  end

  namespace :docs do
    desc "Generates and saves documentation as HTML pages inside #{docs_path} dir"
    task :generate do
      options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(
        {
          filename: Rails.root.join(dsl_path),
          output_dir: Rails.root.join(docs_path),
          delete_output: true
        }
      )
      raw_schema = File.read(options[:filename])
      parser = GraphQLDocs::Parser.new(raw_schema, options)
      parsed_schema = parser.parse
      generator = GraphQLDocs::Generator.new(parsed_schema, options)
      generator.generate
      puts "Docs saved to #{docs_path}"
    end
  end

  desc 'Dumps both the IDL and result of introspection query to files'
  task dump: ['graphql:dump:idl', 'graphql:dump:json']

  task docs: ['graphql:dump:idl', 'graphql:docs:generate']
end
