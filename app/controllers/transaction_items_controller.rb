class TransactionItemsController < ApplicationController  
  before_action :set_transaction, only: [:edit, :update, :destroy]
  before_action :set_debt, only: [:index, :new, :edit, :create, :update]
  before_action :set_transaction_items, only: [:index, :create, :update]

  # GET :debt_id/transactions/
  def index    
    render :index, layout: false
  end

  # GET :debt_id/transaction/new
  def new  	
    @transaction_item = TransactionItem.new()
    @transaction_item.init(@debt, params[:category_number])
    render :new, layout: false
  end

  # GET :debt_id/transactions/1/edit
  def edit
  	render :edit, layout: false
  end

  # POST :debt_id/transactions
  def create
    @transaction_item = TransactionItem.new(transaction_item_params)
    
    if @transaction_item.save
      render :index, layout: false, notice: 'O registro foi salvo com sucesso.'        
    else
      render :new, layout: false, status: :unprocessable_entity
    end
  end

  # PATCH/PUT :debt_id/transactions/1
  def update
    if @transaction_item.update(transaction_item_params)
      render :index, layout: false, notice: 'O registro foi salvo com sucesso.'        
    else
      render :edit, layout: false, status: :unprocessable_entity        
    end
  end

  # DELETE :debt_id/transactions/1
  # DELETE :debt_id/transactions/1.json
  def destroy
    @transaction_item.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'O registro foi removido com sucesso.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_debt
    	@debt = Debt.find(params[:debt_id])
    end

    def set_transaction
      @transaction_item = TransactionItem.find(params[:id])
    end

    def set_transaction_items      
      @transaction_items = @debt.transaction_items.order(:date)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_item_params
      params.require(:transaction_item).permit(:value, 
                                          :value_brl, 
                                          :exchange_rate,
                                          :date, 
                                          :debt_id,
                                          :transaction_info_id,  
                                          :id,
                                          :internalization_date)
    end
end
