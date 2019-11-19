# frozen_string_literal: true

class Product
  attr_accessor :code, :name, :price

  def initialize(code, name, price)
    @code = code
    @name = name
    @price = price
  end

  class << self
    def all
      codes  = %w( 001 002 003 )
      names = ['Lavender heart', 'Personalisted cufflinks', 'Kids T-shirt']
      prices = [9.25, 45.00, 19.95]

      codes.zip(names, prices).map{|p| Product.new *p }
    end

    def find(code)
      all.select{|item| item.code == code}.first
    end
  end
end

class PromotionInterface
  # Should move to validator, but now it's good enought for demo
  def match?
  end

  def apply
  end
end

class OrderPromotion < PromotionInterface
  def initialize(at_least_total, discount_percent = nil, discount = nil, max_discount = nil)
    @at_least_total = at_least_total
    @discount_percent = discount_percent
    @discount = discount
    @max_discount = max_discount || Float::INFINITY
  end

  def apply(total)
    scan(total)
    return 0 unless match?

    discount
  end

  def match?
    @total >= @at_least_total
  end

  private

  def discount
    return [@max_discount, @total * @discount_percent/100.0].min if @discount_percent

    [@max_discount, @discount].min if @discount
  end

  def scan(total)
    @total = total
  end
end

class ItemPromotion < PromotionInterface
  def initialize(code, quantity, price)
    @code = code
    @quantity = quantity
    @price = price
  end

  def apply(items)
    scan(items)
    @list.each do |item|
      discount = item.product.price - @price
      item.discount = discount if discount > item.discount
    end if match?
  end

  def scan(items)
    @list = items.select{|item| item.product.code == @code}

    @list
  end

  def match?
    @list.size >= @quantity
  end
end

class CheckoutItem
  attr_accessor :product
  attr_accessor :discount

  def initialize(code)
    @product = Product.find(code)
    @discount = 0
  end
end

class Checkout
  def initialize(promotional_rules = nil)
    @promotional_rules = promotional_rules
    @items = []
  end

  def scan code
    @items << item(code)
  end

  def total
    [(calculate_total - calculate_discount).round(2), 0].max
  end

  def discount
    calculate_discount
  end

  private

  def item_promotions
    @promotional_rules.select{|promotion| promotion.is_a? ItemPromotion }
  end

  def order_promotions
    @promotional_rules.select{|promotion| promotion.is_a? OrderPromotion }
  end

  def item(code)
    CheckoutItem.new(code)
  end

  def calculate_total
    @total = @items.reduce(0){|total, item| total += item.product.price}
  end

  def calculate_discount
    order_discount + items_discount
  end

  def order_discount
    total = @total || calculate_total
    discount = 0

    order_promotions.each do |promotion|
      discount = [discount, promotion.apply(total)].max
    end

    discount
  end

  def items_discount
    item_promotions.each do |p|
      p.apply @items
    end

    @items.reduce(0){ |discount, item| discount += item.discount }
  end
end

RSpec.describe "Checkout" do
  describe "check promotional rules" do
    promotional_rules = []
    promotional_rules << ItemPromotion.new('001', 2, 8.50)
    promotional_rules << OrderPromotion.new(60, 10)
    #promotional_rules << OrderPromotion.new(80, 15)

    it "should be eq" do
      co = Checkout.new(promotional_rules)
      co.scan '001'
      co.scan '002'
      co.scan '003'

      expected = 66.78
      real = co.total
      expect(real).to eq(expected)
    end

    it "should be eq" do
      co = Checkout.new(promotional_rules)
      co.scan '001'
      co.scan '003'
      co.scan '001'

      expected = 36.95
      real = co.total
      expect(real).to eq(expected)
    end

    it "should be eq" do
      co = Checkout.new(promotional_rules)
      co.scan '001'
      co.scan '002'
      co.scan '001'
      co.scan '003'

      expected = 73.61
      real = co.total
      expect(real).to eq(expected)
    end
  end
end
