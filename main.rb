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

  ONE_PHASE = 1.freeze

  class << self
    # ==== examples
    # generate_contract({start_time: '2017-06-01', end_time: '2017-07-30', price: 1800, cycles: 1}, {}, ...)
    def generate_contract(*phases)
      raise "Please refer to the api doc for #{__method__}" if phases.any? { |phase| !phase.is_a?(Hash) || Time.parse(phase[:start_time]) > Time.parse(phase[:end_time]) }
      raise "NO overlapping between two phases!" if phases_overlap_or_inconsecutive?(phases)
      contract_start = phases.inject([]) {|res, p| res << Time.parse(p[:start_time])}.min
      contract_end = phases.inject([]) {|res, p| res << Time.parse(p[:end_time])}.max
      contract = self.new.tap do |c|
        c.start_date = contract_start
        c.end_date = contract_end
        c.save
      end
      phases.each do |phase|
        contract.renting_phases.create phase
      end
    end
  end

  def generate_invoices

  end

  private

  def phases_overlap_or_inconsecutive?(phases)
    return false if phases.count == ONE_PHASE
    res = phases.sort {|left, right| Time.parse(left[:start_time]) <=> Time.parse(right[:start_time]) }
    res.each_cons(2).any? {|x, y| Time.parse(x[:end_time]) + 1.day != Time.parse(y[:start_time])}
  end
end

class RentingPhase < ActiveRecord::Base
end

class Invoice < ActiveRecord::Base
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  enum units: { daily: 1, monthly: 2 }
end
