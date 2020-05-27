class MonthReportsController < ApplicationController
  
  def show
    start_date = Date.new(2019, 2)
    
    @projection_debt = ProjectionDebt.new(Debt.find(params[:debt_id]), start_date)
    @start_date = @projection_debt.start_date
    @future_transactions = @projection_debt.transaction_items 
    
    render layout: false, 
    			 pdf: "relatorio_mensal",
     			 page_size: "A4"    
  end

end
