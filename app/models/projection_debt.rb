class ProjectionDebt
	attr_accessor :balance_projection
	attr_accessor :debt
	attr_accessor :start_date
	attr_accessor :amortizations_count
	attr_accessor :transaction_items

	def initialize debt, start_date
		self.debt = debt
		self.start_date = start_date
		self.amortizations_count = start_date_to_amortizations_count
		self.transaction_items = build_transaction_items
	end
	
	def build_transaction_items
		result = []		

		projection_period.each_with_index do |future_transaction_count, index|

			debt.transaction_infos.sort_by(&:order).reject(&:withdraw?).each do |transaction_info|

				if (result.empty?) 
					self.balance_projection = debt.transaction_items.where('date <= ?', self.start_date).last.final_outstanding_balance
				else 
					self.balance_projection = result.last.final_outstanding_balance
				end
				
				if !(transaction_info.amortization? && debt.in_grace_period?) && (index % transaction_info.frequency_before_type_cast == 0)
					future_transaction = FutureTransaction.new(debt: debt,
																					projection_debt: self,
																					transaction_info: transaction_info,																					
																					date: transaction_info.payment_date(self.start_date) + future_transaction_count.months - 1.month, 
																					start_balance: balance_projection)

					future_transaction.value = FormulaService.eval(future_transaction)
					future_transaction.value_brl = future_transaction.value * exchange_rate

					result << future_transaction

					self.amortizations_count += 1 if transaction_info.amortization?
				end
			end

		end

		result
	end

	def exchange_rate
		if debt.interests.where('date <= ?', self.start_date).last.present?
		 	debt.interests.where('date <= ?', self.start_date).last.exchange_rate
		else debt.withdraws.where('date <= ?', self.start_date).last.present?
			debt.withdraws.where('date <= ?', self.start_date).last.exchange_rate
		end
	end

	def brl_lacking_total_by date, category_number
		self.transaction_items.reduce(0){ |sum, transaction| transaction.date.year == date.year && transaction.date > (date + 1.month) && transaction.transaction_info.category_number == category_number ? sum + transaction.value_brl : sum }
	end

	def brl_total_by year, category_number
		self.transaction_items.reduce(0){ |sum, transaction| transaction.date.year == year && transaction.transaction_info.category_number == category_number ? sum + transaction.value_brl : sum }
	end

	def projection_period
		if debt.in_grace_period? 
			1..grace_period_in_months(self.start_date)
		elsif debt.in_amortization_period?
			1..(debt.loan_term - debt.paid_payments_count(:amortizations, self.start_date))
		else debt.done?
			0..0
		end		
	end

	def grace_period_in_months end_date
		(debt.grace_period_payments_number + debt.loan_term - debt.paid_payments_count(:interests, end_date))
	end

	def start_date_to_amortizations_count
		(self.start_date.year * 12 + self.start_date.month) - (debt.grace_period.year * 12 + debt.grace_period.month)
	end

	def outstanding_balance
		self.balance_projection	
	end

	private
		def method_missing(method_name, *args, &block)	    
	    debt.send(method_name)
	  end
end
