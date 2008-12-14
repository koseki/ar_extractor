def fixture_entry(table_name, obj)
  res = []
  klass = table_name.singularize.camelize.constantize
  res << "#{table_name.singularize}#{obj['id']}:"
  klass.columns.each do |column|
    name = column.name
    value = obj[column.name]

		# How about CR or CR+LF?
    if value.is_a? String and value =~ /\n/
      res << "  #{name}: |\n    " + value.split("\n").join("\n    ")
    else
      res << "  #{name}: #{value}"
    end
  end
  res.join("\n")
end
   
namespace :db do
  namespace :fixtures do
    desc "Extract database data to YAML fixtures."
    task :extract => :environment do
      sql = "SELECT * FROM %s ORDER BY id"
      sql_no_id = "SELECT * FROM %s"
      ActiveRecord::Base.establish_connection
      fixtures_dir = "#{RAILS_ROOT}/"
      fixtures_dir += "test" unless FileTest.exist?(fixtures_dir += "spec")
      fixtures_dir += "/fixtures/"
      FileUtils.mkdir_p(fixtures_dir)
 
      if ENV["FIXTURES"]
        table_names = ENV["FIXTURES"].split(/,/)
      else
        table_names = (ActiveRecord::Base.connection.tables - SKIP_TABLES)
      end
 
      table_names.each do |table_name|
        File.open("#{fixtures_dir}#{table_name}.yml", "w") do |file|
          begin
            objects  = ActiveRecord::Base.connection.select_all(sql % table_name)
          rescue
            objects  = ActiveRecord::Base.connection.select_all(sql_no_id % table_name)
          end
          objects.each do |obj|
            file.write fixture_entry(table_name, obj) + "\n\n"
          end
        end
      end
    end
  end
end
