class TransactionInfo < ApplicationRecord
	BASIC_TYPES = { 1 => {name: 'Desembolso', operation: '+', slug: 'D', order: 1}, 							    
									2 => {name: 'Amortização', operation: '-', slug: 'A', order: 4},
									3 => {name: 'Juros', operation: '-', slug: 'J', order: 2},
									4 => {name: 'Encargos', operation: '-' , slug: 'E', order: 3} }
	
	enum frequency: { mensal: 1, 
										trimestral: 3, 
										semestral: 6 }

	belongs_to :debt

	has_many :items, class_name: 'TransactionItem', foreign_key: :transaction_info_id

	def name
		BASIC_TYPES[category_number][:name]
	end

	def payment_date date = Date.today
		Date.new(date.year, date.month, payment_day)
	end

	def reference_period
		(payment_date - 1.month + 1.day)..payment_date
	end

	def next_amount
		FormulaService.eval formula, debt
	end
	
	def category
		OpenStruct.new(BASIC_TYPES[category_number])
	end

	def withdraw?
		category_number == 1
	end

	def amortization?
		category_number == 2
	end

	def charge?
		category_number == 4
	end
	
	def order
		category.order
	end

end