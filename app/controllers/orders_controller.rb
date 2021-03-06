class OrdersController < ApplicationController
  before_action :authenticate_user!, only: [:new]
  before_action :set_card
  before_action :set_product
  def new
    if @product.buyer_id.present?
      redirect_to product_path(@product.id)
    end
    user_address = Address.where(user_id: current_user.id).first 
    @postal_address = user_address.postal_prefectures.name
    @p_numder_first3 = user_address.postal_number.to_s[0..2]
    @p_numder_last4 = user_address.postal_number.to_s[3..6]
    if @card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      card_information = customer.cards.retrieve(@card.card_id)
      @card_info_last4 = card_information.last4
      @card_brand = card_information.brand
      case @card_brand
      when "Visa"
        @card_src = "visa.png"
      when "JCB"
        @card_src = "jcb.png"
      when "MasterCard"
        @card_src = "master-card.png"
      when "American Express"
        @card_src = "american_express.png"
      when "Diners Club"
        @card_src = "dinersclub.png"
      when "Discover"
        @card_src = "discover.png"
      end
    end
  end

  def create
    if @card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      Payjp::Charge.create(
      amount: @product.price,
      customer: @card.customer_id,
      currency: 'jpy',
      description: "商品名:" + @product.title,
      metadata: {nickname_id: current_user.nickname}
      )
      @product.update(buyer_id: current_user.id)
      @product.save
      redirect_to controller: "products", action: "index"
      else
        flash[:error] = "クレジットカードを登録してください"
        redirect_to action: "new"
    end
  end

  def card_order_add
  end

  def card_registration
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
    if params['payjp-token'].present?
      customer = Payjp::Customer.create(
        description: "ニックネーム：" + current_user.nickname, 
        email: current_user.email,
        card: params['payjp-token'], 
        metadata: {user_id: current_user.id}
      )
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to action: "new"
      else
        redirect_to action: "card_order_add",alert: "登録できませんでしました"
      end
    else
      redirect_to action: "card_order_add",alert: "トークンが生成されていません"
    end
  end
private
  def set_card
    @card = Card.where(user_id: current_user.id).first if Card.where(user_id: current_user.id).present?
    end
  end
  def set_product
    @product = Product.find(params[:product_id])
  end
