require 'yaml'
Dir.glob(File.dirname(__FILE__) + '/services/*.rb', &method(:require))

desc "Percolation"
task :percolation do
  ennv = ENV['RACK_ENV'] || 'development'
  config = YAML::load_file("config/app.yml")[ennv]
  index_service = Services::Percolation.new(config)
  index_service.re_index
  index_service.list_document
end