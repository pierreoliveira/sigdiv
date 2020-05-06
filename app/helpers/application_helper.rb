module ApplicationHelper
	def big_decimal_to_currency value, precision
		number_to_currency value, precision: precision, unit: ''
	end
end
