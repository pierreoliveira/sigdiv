class Debt < ApplicationRecord	
	belongs_to :creditor
	belongs_to :financial_agent, class_name: 'Creditor', optional: true
	belongs_to :currency

	has_many :charges, inverse_of: :debt
	has_many :attachments
	has_many :transactions
	
	accepts_nested_attributes_for :charges, reject_if: :all_blank, allow_destroy: true

	enum category: [:interno, :externo]
	enum amortization_type: [:sac, :price, :single]
	enum amortization_frequency: [:mensal, :trimestral, :semestral], _prefix: :amortization_frequency
	enum grace_period_rate_frequency: [:mensal, :trimestral, :semestral], _prefix: :grace_period_rate_frequency
	enum legislation_level: [:federal, :estadual, :municipal]
	
	validates :code, presence: true, numericality: { only_integer: true }, length: { is: 6 }
	validates :contract_value, presence: true
	validates :signature_date, presence: true
	validates :amortization_period, presence: true
	validates :currency, presence: true
	validates :loan_term, presence: true
	validates :payment_day, presence: true, :inclusion => 1..30

	def self.search code_query = '', name_query = '', creditor_query = '', signature_year_query = '', status_query = ''
		result = Debt.all

		if code_query.present? 
			return Debt.where(code: code_query)
		elsif creditor_query.present?
			result = result.where(creditor_id: creditor_query)
		end

		result = result.where("name ILIKE ?", "%#{name_query}%") if name_query.present?
		result = result.where(signature_date: date_range_from_year(signature_year_query.to_i)) if signature_year_query.present?

		result = result.select{ |debt| debt.status == status_query } if status_query.present?

		result
	end
  # Desembolsos
	def withdraws
		transactions.where(type: 'Withdraw')
	end
	# Amortizações
	def payments
		transactions.where(type: 'Payment')
	end 
  # Próxima parcela
	def next_instalment		
		outstanding_balance * instalment_formula_numerator / instalment_formula_denominator
	end	
    
    ['next_instalment', 'amortization', 'interest', 'outstanding_balance'].each do |method_name|
    	define_method :"show_#{method_name}" do 
    		Decimal.new(self.send(method_name).to_f)
    	end
    end

	def amortization
		next_instalment - interest
	end
	# Juros
	def interest final_date = Date.today
		withdraws_total = 0
		withdraws.where(date: reference_period(final_date)).each do |withdraw|
			withdraws_total += withdraw.value * interest_rate / 360 * (Date.new(final_date.year, final_date.month, payment_day) - (withdraw.date - 1.day)).to_i
		end
		(30 * outstanding_balance * interest_rate / 360 ) - withdraws_total
	end

	# Taxas
	def charges_total
		# TODO
	end
	
	def contract_value_brl
		contract_value / currency.to_brl	
	end

	def status
		if in_grace_period?
			return 'Carência'
		elsif in_amortization_period?
			return 'Amortização'
		elsif finished?
			return 'Finalizada'
		end
	end

	def in_grace_period?
		grace_period > Date.today && !finished?
	end

	def in_amortization_period?
		grace_period < Date.today && !finished?
	end

	def finished?
		#balance == 0
		false
	end

	def balance
		# instalment_sum == payments.sum(:value_cents)
	end

	# Saldo devedor
	def outstanding_balance final_date = Date.today
		withdraws.where(date: signature_date..final_date).sum(:value) - payments.where(date: signature_date..final_date).sum(:principal)
	end

	private

		def self.date_range_from_year year
			Date.new(year)..(Date.new(year + 1) - 1.day)
		end

		# Taxa de juros
		def interest_rate
			BigDecimal(Dentaku(interest_rate_formula)) / 100
		end

		def charges_total
			charges.reduce(0) { |sum, charge| sum + charge.total }
		end

		def instalment_formula_numerator
			( ( (1 + interest_rate_per_month) ** (loan_term - payments.count) ) * interest_rate_per_month )
		end

		def instalment_formula_denominator
			( ( ( 1 + interest_rate_per_month ) ** (loan_term - payments.count) ) - 1 )
		end

		def interest_rate_per_month
			interest_rate / 12
		end

		# Periodo de referência para calculo de juros e taxas
		def reference_period final_date = Date.today
			period_end = Date.new(final_date.year, final_date.month, payment_day)
			(period_end - 1.month + 1.day)..period_end
		end
end
