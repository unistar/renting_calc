ENV['RACK_ENV'] ||= 'development'

ActiveRecord::Base.establish_connection(CONFIG[ENV['RACK_ENV']])

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.tables.include? 'contracts'
    create_table :contracts do |table|
      table.column :start_date, :date
      table.column :end_date, :date
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'renting_phases'
    create_table :renting_phases do |table|
      table.column :start_date, :date
      table.column :end_date, :date
      table.column :price, :integer
      table.column :cycles, :integer
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'invoices'
    create_table :invoices do |t|
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :due_date, :date
      t.column :total, :integer
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'line_items'
    create_table :line_items do |t|
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :unit_price, :integer
      t.column :units, :integer  # use enum
      t.column :total, :integer
    end
  end
end

