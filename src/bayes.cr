require "./bayes/*"

module Bayes
  class Text
    getter words, parsed, original
    @@punctuation_regex = /[\/\[\]\{\}!@#$%^&*()-=_+|;':",.<>?']/
    @@apostrophe_regex = /[']/

    def punctuation_regex
      @@punctuation_regex
    end

    def brackets_regex
      @@brackets_regex
    end

    def slash_regex
      @@slash_regex
    end

    def apostrophe_regex
      @@apostrophe_regex
    end

    def initialize(original)
      @original = original
      @parsed = parse(original)
      @words = {} of String => Int32
      add_words(@parsed)
      puts @words.inspect
    end

    def add_words(list)
      list.each do |word|
        if @words.has_key? word
          @words[word] += 1
        else
          @words[word] = 1
        end
      end
    end

    def parse(text)
      text.gsub(apostrophe_regex, "")
          .gsub(punctuation_regex, " ")
          .split(" ")
          .select { |item| !(item == " " || item == "") }
          .map { |word| word.downcase }
    end
  end

  class Category
    getter words

    def initialize(name, count)
      @name = name
      @count = 0
      @words = {} of String => Int32
    end

    def add_words(words)
      words.each do |word, count|
        if @words.has_key? word
          @words[word] += count
        else
          @words[word] = count
        end
      end
    end

    def increment_count
      @count += 1
    end

    def count
      @words.reduce(0) do |acc, _, count|
        acc += count
        acc
      end
    end
  end

  class Classifier
    getter categories, total_words

    def initialize(*categories)
      @categories = {} of String => Category
      categories.each do |name|
        @categories[name] = Category.new(name, 0)
      end
      @total_words = 0
    end

    #
    # Provides a general training method for all categories specified in Bayes#new
    # For example:
    #     b = Classifier::Bayes.new 'This', 'That', 'the_other'
    #     b.train :this, "This text"
    #     b.train "that", "That text"
    #     b.train "The other", "The other text"

    def train(category, text)
      cat = @categories[category]
      return puts "Error: Unrecognized Category '#{category}'" if cat == nil
      cat.increment_count
      training_text = Text.new(text)
      cat.add_words(training_text.words)
      @total_words += training_text.parsed.size
    end

    #
    # Returns the scores in each category the provided +text+. E.g.,
    #    b.classifications "I hate bad words and you"
    # => {"Uninteresting"=>-12.6997928013932, "Interesting"=>-18.4206807439524}
    # The largest of these scores (the one closest to 0) is the one picked out by #classify

    # def classify(text)
    #   score = Hash.new
    #   training_count = @category_counts.values.inject { |x, y| x + y }.to_f
    #   @categories.each do |category, category_words|
    #     score[category.to_s] = 0
    #     total = category_words.values.inject(0) { |sum, element| sum + element }
    #     text.word_hash.each do |word, count|
    #       s = category_words.has_key?(word) ? category_words[word] : 0.1
    #       score[category.to_s] += Math.log(s/total.to_f)
    #     end
    #     # now add prior probability for the category
    #     s = @category_counts.has_key?(category) ? @category_counts[category] : 0.1
    #     score[category.to_s] += Math.log(s / training_count)
    #   end
    #   return score
    # end

    #
    # Returns the classification of the provided +text+, which is one of the
    # categories given in the initializer. E.g.,
    #    b.classify "I hate bad words and you"
    # => 'Uninteresting'

    # def classify(text)
    #   (classifications(text).sort_by { |a| -a[1] })[0][0]
    # end
    #
    # Provides a list of category names
    # For example:
    #     b.categories
    # => ['This', 'That', 'the_other']
    def categories # :nodoc:
      @categories.keys.collect { |c| c.to_s }
    end

    #
    # Allows you to add categories to the classifier.
    # For example:
    #     b.add_category "Not spam"
    #
    # WARNING: Adding categories to a trained classifier will
    # result in an undertrained category that will tend to match
    # more criteria than the trained selective categories. In short,
    # try to initialize your categories at initialization.
    def add_category(category)
      @categories[category.prepare_category_name] = Hash.new
    end

    # alias append_category add_category
  end
end

b = Bayes::Classifier.new("Jason", "Michael")
b.train("Jason", "Once, upon {} a time")
