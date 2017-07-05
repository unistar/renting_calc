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
  has_many :renting_phases, dependent: :destroy

  ONE_PHASE = 1.freeze
  DAYS_IN_A_YEAR = 365.0.freeze
  MONTHS_IN_A_YEAR = 12.freeze
  FEWEST_DAYS_IN_A_MONTH = 28.freeze

  class << self
    # ==== examples
    # generate_contract({start_time: '2017-06-01', end_time: '2017-07-30', price: 1800, cycles: 1}, {}, ...)
    def generate_contract(*phases)
      raise "Please refer to the api doc for #{__method__}" if phases.any? { |phase| !phase.is_a?(Hash) || Date.parse(phase[:start_time]) > Date.parse(phase[:end_time]) }
      raise "NO overlapping between two phases!" if phases_overlap_or_inconsecutive?(phases)
      contract_start = phases.inject([]) {|res, p| res << Date.parse(p[:start_time])}.min
      contract_end = phases.inject([]) {|res, p| res << Date.parse(p[:end_time])}.max
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
    renting_phases.each do |rp|
      time_cycles = split_cycles([], rp.start_date, rp.end_date, rp.cycles)
      time_cycles.each do |cycle|
        invoice_creation(cycle[0], cycle[1], rp.price)
      end
    end
  end

  private

  def phases_overlap_or_inconsecutive?(phases)
    return false if phases.count == ONE_PHASE
    res = phases.sort {|left, right| Date.parse(left[:start_time]) <=> Date.parse(right[:start_time]) }
    res.each_cons(2).any? {|x, y| Date.parse(x[:end_time]) + 1.day != Date.parse(y[:start_time])}
  end

  def invoice_creation(start_time, end_time, price)
    invoice = Invoice.find_or_create_by(start_date: start_time, end_date: end_time, due_date: Date.parse("#{start_time.year}-#{start_time.month - 1}-15"))
    if start_time + 1.month - 1.day > end_time # get the line item for renting for less than a month
      line_item_less_than_a_month(invoice, start_time, end_time, price)
    else # over a month
      months = (end_time - start_time).to_i / REGULAR_DAYS_IN_A_MONTH
      rent_end = start_time + months.month - 1.day
      if rent_end > end_time
        months -= 1
      end
      total_price = price * months
      rent_end = start_time + months.month - 1.day
      invoice.line_items.create(start_date: start_time, end_date: rent_end, unit_price: price, unit: LineItem.units[:monthly], total: total_price)
      line_item_less_than_a_month(invoice, rent_end + 1.day, end_time, price) if rent_end != end_time
    end
    invoice_total = invoice.line_items.inject(0) {|res, item| res + item.total}
    invoice.update_attributes(total: invoice_total)
  end

  def line_item_less_than_a_month(invoice, start_time, end_time, price)
    unit_price = price.to_i * MONTHS_IN_A_YEAR / DAYS_IN_A_YEAR
    days = end_time == start_time ? ONE_PHASE : end_time - start_time
    total_price = unit_price * days.to_i
    invoice.line_items.create(start_date: start_time, end_date: end_time, unit_price: unit_price, unit: LineItem.units[:daily], total: total_price)
  end

  def split_cycles(res, start_time, end_time, cycles)
    start = start_time
    finish = start + cycles.to_i * month - 1.day
    return res << [start, end_time] if finish >= end_time
    res << [start, finish]
    split_cycles(res, finish + 1.day, end_time, cycles)
  end
end

class RentingPhase < ActiveRecord::Base
end

class Invoice < ActiveRecord::Base
  has_many :line_items, dependent: :destroy
end

class LineItem < ActiveRecord::Base
  enum unit: { daily: 1, monthly: 2 }
end
