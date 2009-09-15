class AddToWallet < Riddl::Implementation
  include MarkUSModule

  def response
    puts "Executing AddToWallet"
    @p.each do |param|
      pp param
    end
  end
end
