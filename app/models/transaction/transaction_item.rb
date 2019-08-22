class TransactionItem < ApplicationRecord
	belongs_to :transaction_info
	has_one :debt, through: :transaction_info

	before_save :set_start_balance, if: :blank_start_balance?

  validates :value_brl, presence: true
	validates :exchange_rate, presence: true
	validates :value, presence: true
	
	def editable?
		true
	end

	def final_outstanding_balance
		if amortization? || withdraw?
			Dentaku("#{start_balance} #{transaction_info.category.operation} #{value}")
		else
			start_balance
		end
	end

	def period
		result = ((transaction_info.payment_date) - date).to_i
		result = 30 if result == 31
		result
	end

	def init(debt, category_number)
		self.debt = debt
		self.transaction_info = debt.transaction_infos.find_by(category_number: category_number)
	end

	def future_transaction?
		new_record? ? true : false
	end

	def withdraw?
		transaction_info.category_number == 1
	end

	def amortization?
		transaction_info.category_number == 3
	end


	private
		def set_start_balance
			self.start_balance = debt.outstanding_balance
		end

		def blank_start_balance?
			self.start_balance.blank?
		end
end