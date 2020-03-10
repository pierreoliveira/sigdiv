class AddBindWithdrawToTransactionInfos < ActiveRecord::Migration[5.2]
  def change
    add_column :transaction_infos, :bind_withdraw, :boolean
  end
end
