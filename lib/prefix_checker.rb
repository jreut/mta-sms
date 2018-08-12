require 'did_you_mean'

class PrefixChecker
  def initialize(dictionary:)
    @dictionary = dictionary
  end

  def correct(input)
    corrections = @dictionary.select { |word| word.start_with? input }
    if corrections.empty?
      corrections = DidYouMean::SpellChecker
        .new(dictionary: @dictionary)
        .correct(input)
    end
    corrections
  end
end
