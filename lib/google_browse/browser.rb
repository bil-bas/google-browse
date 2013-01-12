# Google search CLI browser that can open links into a browser.
module GoogleBrowse
  class << self
    def search(*args); Browser.new *args; end
  end

  class Browser
    DEFAULT_RESULTS_PER_PAGE = 5
    MIN_RESULTS_PER_PAGE = 1
    MAX_RESULTS_PER_PAGE = 20 # Avoid being rude to Google.
    NUM_COLUMNS = 79

    class << self
      def search(*args); new *args; end
    end

    # @option :results_per_page [Integer] (5) Number of results to show per page.
    # @option :query [String] Initial search string.
    def initialize(options = {})
      options = {
        results_per_page: DEFAULT_RESULTS_PER_PAGE,
      }.merge! options

      @results_per_page = [
          [MIN_RESULTS_PER_PAGE, options[:results_per_page]].max,
          MAX_RESULTS_PER_PAGE
      ].min

      @quit = false

      if options[:query]
        @scraper = Scraper.new options[:query]
      else
        @scraper = nil
        input_new_search
      end

      @page_number = 0

      puts
      list_links
      navigate until quit?
    end

    protected
    def quit?; @quit end
    # Index, in @links, of the first link to show.
    def first_link_index; @page_number * @results_per_page end
    def link_range; first_link_index..last_link_index end 

    protected
    # Index, in @links, of the last link to show.
    def last_link_index
      if @scraper.more_pages?
        first_link_index + @results_per_page - 1
      else
        @scraper.num_links - 1
      end
    end

    protected
    # Are we showing the last page?
    def last_page?
      !@scraper.more_pages? && last_link_index == (@scraper.num_links - 1)
    end  

    protected
    def underline(title)
      puts title
      puts '_' * title.length  
    end

    protected
    def list_links
      limit_page_number

      # Ensure we have enough links downloaded to display them.
      first, last = first_link_index + 1, last_link_index + 1

      # Force scraper to read as high as it can, then limit the page number.
      @scraper[last_link_index] 
      @page_number = [@page_number, @scraper.num_links.div(@results_per_page)].min

      if @scraper.num_links > 0
        num_columns = last.to_s.length

        puts
        underline "Page #{@page_number + 1}, showing results #{first} to #{last} for: #{@scraper.query}"
        
        @scraper[link_range].each.with_index(first) do |link, i|
          indent = ' ' * (num_columns + 2)
          puts
          max_width = NUM_COLUMNS - indent.size
          puts "#{i.to_s.rjust num_columns}: #{limit_text link.title, max_width}"
          puts "#{indent}#{limit_text link.body, max_width}"
          puts "#{indent}#{link.url}"
        end
      else
        # No joy. Let's try a new search...
        puts "No results for #{@scraper.query}!"
        input_new_search
        list_links
      end
    end

    protected
    def limit_text(text, length)
      if text.size < length
        text
      else
        text[0, length - 3] + '...'
      end
    end

    protected
    def limit_page_number
      unless @scraper.more_pages?
        @page_number = @scraper.num_links.div @results_per_page
      end
    end

    protected
    def navigate
      # Ask the user for instructions.
      puts

      next_ = last_page? ? '' : 'N/'
      previous = @page_number.zero? ? '' : 'p/'
      print "Enter number of link to browse or [#{next_}#{previous}h/s/q]: "
      input = $stdin.gets.strip

      case input.upcase
      when 'N', '' # Next page.
        unless last_page?
          @page_number += 1 
          list_links
        end

      when 'P' # Previous page.
        if @page_number > 0
          @page_number -= 1
          list_links
        end

      when 'H', '?'
        puts <<-END_OF_TEXT

  Browser help
  ------------

  N(next) - Next page (default action).
  P(revious) - Previous page.
  H(elp) - This help message.
  S(earch) - Enter a new query string.
  Q(uit) - Quit the browser.

  Enter a link number to open it in your default browser for viewing.
  END_OF_TEXT

      when 'S' # Search
        input_new_search

        list_links

      when 'Q' # Quit.
        @quit = true

      else # Follow link to page.
        link_index = input.to_i - 1
        if link_index.between? first_link_index, last_link_index
          link = @scraper[link_index]
          puts
          puts "Navigating to #{link_index}: #{link.title} (#{link.url})"
          puts
          Launchy.open link.url
          puts
        else
          puts "Bad input: #{input}"
        end
      end 

      puts   
    end

    protected
    def input_new_search
      input = ''
      while input.empty?
        puts
        print "Enter search string: "
        input = $stdin.gets.strip
      end

      if @scraper
        @scraper.query = input
      else
        @scraper = Scraper.new input
      end

      @page_number = 0
    end
  end
end





