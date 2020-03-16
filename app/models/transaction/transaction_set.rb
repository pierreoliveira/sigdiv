class TransactionSet
	attr_accessor :transactions

	def self.build debt, start_date
		transaction_items = debt.transaction_items.includes(:transaction_info) + ProjectionDebt.new(debt, start_date).transaction_items
      
    transaction_items = transaction_items.sort_by { |t| [t.date, t.transaction_info.category_number, t.transaction_info.slug] }
		transaction_items	
	end

end