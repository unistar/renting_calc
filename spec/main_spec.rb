ENV['RACK_ENV'] ||= 'test'
require 'rspec'
require_relative '../main'

describe Contract do
  let(:phase_1) {{start_time: '2017-06-01', end_time: '2017-07-30', price: 1800, cycles: 1}}
  let(:phase_2) {{start_time: '2017-07-31', end_time: '2017-11-30', price: 1800, cycles: 2}}
  before :each do
    Contract.delete_all
    Invoice.delete_all
    RentingPhase.delete_all
    LineItem.delete_all
  end
  context 'Constants in contract' do
    it 'is the right constant' do
      expect(Contract::DAYS_IN_A_YEAR).to eq 365.0
    end
  end

  context 'Generate contract' do
    it 'functions properly' do
      Contract.generate_contract(phase_1, phase_2)
      contract = Contract.last
      expect(contract.end_date).to eq Date.parse(phase_2[:end_time])
    end

    it 'complains about the date overlap' do
      expect { Contract.generate_contract(phase_1, phase_2.merge(start_time: '2017-07-29')) }.to raise_error('NO overlapping between two phases!')
    end

    it 'complains about the date inconsecutive' do
      expect { Contract.generate_contract(phase_1, phase_2.merge(start_time: '2017-08-29')) }.to raise_error('NO overlapping between two phases!')
    end
  end

  context 'Generate invoices' do
    it 'functions properly' do
      contract = Contract.generate_contract(phase_1, phase_2)
      contract.generate_invoices
      expect(Invoice.count).to eq 5
    end

    it 'matches the request' do
      contract = Contract.generate_contract(phase_1.merge(start_time: '2017-08-05', end_time: '2017-10-04'), phase_2.merge(start_time: '2017-10-05', end_time: '2017-12-10', cycles: 1))
      contract.generate_invoices
      expect(Invoice.count).to eq 5
    end
  end
end
