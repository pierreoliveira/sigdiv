class FormulasController < ApplicationController
	def show
		render json: params[:formula] + 'ok'
	end
end
