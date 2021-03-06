class WelcomeController < ApplicationController
  skip_before_filter :verify_authenticity_token  
  def index
  end
  def order
  end
  def process_payment
    Conekta.api_key = "1tv5yJp3xnVZ7eK67m4h"
    if params['isSubscription'] == "true"
      params['planId'] = params['planId'].gsub(/[^0-9A-Za-z_-]/, '').gsub(' ', '_')
      customer = Conekta::Customer.create({cards: [params['conektaTokenId']]})
      begin
        plan = Conekta::Plan.find(params['planId'])
      rescue Conekta::Error => e
        plan = Conekta::Plan.create({
					id:  params['planId'],
					name:  params['productDescription'],
					amount:  (params['productPrice'].to_f * 100).to_i,
					currency:  "MXN",
					interval:  "month",
					trial_period_days:  15,
					expiry_count:  12
					}
				)
        subscription = customer.create_subscription({
  				plan: params['planId']
				})
        redirect_to :charges
      end
    else
      charge = Conekta::Charge.create({
        amount:  (params['productPrice'].to_f * 100).to_i,
			  currency:  'mxn', 
        description:  params['productDescription'],
			  card: params['conektaTokenId']
			  })
    end
    @charge = Charge.new(id: charge.id,
	    amount:  charge.amount,
	    livemode: charge.livemode,
	    created_at: charge.created_at,
	    status: charge.status,
	    currency: charge.currency,
	    description: charge.description,
	    reference_id: charge.reference_id,
	    failure_code: charge.failure_code,
	    failure_message: charge.failure_message,
	    card_name: charge.payment_method.name,
	    card_exp_month: charge.payment_method.exp_month,
	    card_exp_year: charge.payment_method.exp_year,
	    card_auth_code: charge.payment_method.auth_code,
	    card_last4: charge.payment_method.last4,
	    card_brand: charge.payment_method.brand
    )
    respond_to do |format|
      if @charge.save
        format.html { redirect_to @charge, notice: 'Charge was successfully created.' }
        format.json { render action: 'show', status: :created, location: @charge }
      else
        raise "Unable to create your charge!"
      end
    end
  end
end
