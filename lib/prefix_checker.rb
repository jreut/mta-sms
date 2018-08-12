require 'did_you_mean'

require 'dry/monads/list'

M = Dry::Monads

class PrefixChecker
  def initialize(dictionary:)
    @dictionary = dictionary
  end

  def call(input)
    M::List.new(@dictionary)
      .select { |word| word.start_with? input }
      .head
      .or do
        M::List.new(
          DidYouMean::SpellChecker
            .new(dictionary: @dictionary)
            .correct(input)
        ).head
      end
  end
end
