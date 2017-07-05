ENV['RACK_ENV'] ||= 'development'

ActiveRecord::Base.establish_connection(CONFIG[ENV['RACK_ENV']])

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.tables.include? 'contracts'
    create_table :contracts do |t|
      t.column :start_date, :date
      t.column :end_date, :date
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'renting_phases'
    create_table :renting_phases do |t|
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :price, :integer, default: 0
      t.column :cycles, :integer, default: 0
      t.column :contract_id, :integer, null: false
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'invoices'
    create_table :invoices do |t|
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :due_date, :date
      t.column :total, :integer, default: 0
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'line_items'
    create_table :line_items do |t|
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :unit_price, :integer, default: 0
      t.column :unit, :integer, default: 0  # use enum
      t.column :total, :integer, default: 0
      t.column :invoice_id, :integer, null: false
    end
  end
end

