ENV['RACK_ENV'] ||= 'development'
app_root = File.expand_path('../', __FILE__)
require 'yaml'
CONFIG = YAML.load_file(File.join(app_root, 'config.yml'))

require 'active_support'
require 'active_record'
require 'bundler'
require 'pry'
require_relative 'tables'

Bundler.require :default, ENV['RACK_ENV'].to_sym

class Contract < ActiveRecord::Base
  has_many :renting_phases
end

class RentingPhase < ActiveRecord::Base

end

class Invoice < ActiveRecord::Base
  has_many :line_items
end

class LineItem < ActiveRecord::Base

end

binding.pry

