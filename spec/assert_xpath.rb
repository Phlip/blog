
module AssertXPath  # TODO  add expect() notation for RSpec

  # TODO  use or lose this


  ##
  # +assert_xml+ validates XML in its string argument, +xml+, and prepares it for
  # further testing with +assert_xpath+. It optionally raises a Minitest assertion
  # failure with any XML syntax errors it finds.
  #
  # ==== Parameters
  #
  # * +xml+ - A string containing XML.
  # * +strict+ - Optional boolean deciding whether to raise syntax errors. Defaults to +true+.
  #
  # ==== Returns
  #
  # If the XML passes inspection, it places the XML's Document Object Model into
  # the variable <code>@selected</code>, for +assert_xpath+ and +refute_xpath+ to
  # interrogate.
  #
  # Finally, it returns <code>@selected</code>, for custom testing.
  #
  def assert_xml(xml, strict = true)
    @selected = Nokogiri::XML(xml)
    assert @selected.xml?, 'Nokogiri should identify this as XML.'
    strict and _assert_no_xml_or_html_syntax_errors(xml)
    return @selected
  end

  ##
  # +assert_html+ validates an HTML string, and prepares it for further
  # testing with +assert_xpath+ or +refute_xpath+.
  #
  # ==== Parameters
  #
  # * +html+ - Optional string of HTML. Defaults to <code>response.body</code>.
  # * +strict+ - Optional boolean deciding whether to raise syntax errors. Defaults to +true+.
  #
  # ==== Examples
  #
  # Call +assert_html+ in one of several ways.
  #
  # In a test environment such as a test suite derived from
  # +ActionController::TestCase+ or +ActionDispatch::IntegrationTest+, if a call
  # such as <code>get :action</code> has prepared the +response+ instance variable,
  # you may call +assert_html+ invisibly, by letting +assert_xpath+ call it for you:
  #
  #   get :new
  #   assert_xpath '//form[ "/create" = @action ]'
  #
  # In that mode, +assert_html+ will raise a Minitest failure if the HTML contains
  # a syntax error. If you cannot fix this error, you can reduce +assert_html+'s
  # aggressiveness by calling it directly with +false+ in its second parameter:
  #
  #   get :new
  #   assert_html response.body, false
  #   assert_xpath '//form[ "/create" = @action ]'
  #
  # ==== Returns
  #
  # +assert_html+ returns the <code>@selected</code> Document Object Model root element,
  # for custom testing.
  #
  def assert_html(html = nil, strict = true)
    html ||= response.body
    @selected = Nokogiri::HTML(html)
    assert @selected.html?, 'Nokogiri should identify this as HTML.'

    if strict
      _assert_no_xml_or_html_syntax_errors(html)

      if strict == :html5 || html =~ /\A\s*<!doctype html>/i
        deprecated = %w(acronym applet basefont big center dir font frame
                              frameset noframes isindex nobr menu s strike tt u)

        deprecated.each do |dep|
          refute_xpath "//#{dep}", "The <#{dep}> element is deprecated."
        end

        deprecated_attributes = [
          [ 'height', [ 'table', 'tr', 'th', 'td' ] ],
          [ 'align', %w(caption iframe img input object legend table
                                hr div h1 h2 h3 h4 h5 h6
                                p col colgroup tbody td tfoot th thead tr) ],
          [ 'valign', [ 'td' 'th' ] ],
          [ 'width', [ 'hr', 'table', 'td', 'th', 'col', 'colgroup', 'pre' ] ],
          [ 'name', [ 'img' ] ]
        ]

        deprecated_attributes.each do |attr, tags|
          tags.each do |tag|
            refute_xpath "//#{tag}[ @#{attr} ]", "The <#{tag} #{attr}> attribute is deprecated."
          end
        end

        refute_xpath '//table/tr', '<table> element missing <thead> or <tbody>.'
        refute_xpath '//td[ not( parent::tr ) ]', '<td> element without <tr> parent.'
        refute_xpath '//th[ not( parent::tr ) ]', '<th> element without <tr> parent.'
        # TODO  fix Warning: <input> anchor "pc_contract_create_activity_" already defined
        #         in pc_contracts_controller new
        # refute_xpath '//img[ @full_size ]',   '<img> contains proprietary attribute "full_size".'
        # CONSIDER  tell el-Goog not to do this: refute_xpath '//textarea[ @value ]',  '<textarea> contains proprietary attribute "value".'
        # CONSIDER  tell el-Goog not to do this: refute_xpath '//iframe[ "" = @src ]', '<iframe> contains empty attribute "src".'

        # A document must not include both a meta element with an http-equiv attribute whose value is content-type, and a meta element with a charset attribute.
        # Consider avoiding viewport values that prevent users from resizing documents.
        #
        # From line 9, column 1; to line 9, column 103
        #
        # s</title>↩<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">↩<meta
        #
        # The type attribute is unnecessary for JavaScript resources.
        #
        # From line 394, column 9; to line 394, column 46
        #
        # >↩        <script type="application/javascript">↩
        # TODO  tidy sez:  Warning: <a> escaping malformed URI reference
        # TODO  tidy sez:  Warning: <a> illegal characters found in URI

      end
    end

    return @selected
  end

  def _assert_no_xml_or_html_syntax_errors(xml) #:nodoc:
    errs =
      @selected.errors.map do |error|
        if error.level > 0
          err = "#{error.level > 1 ? 'Error' : 'Warning'} on line #{error.line}, column #{error.column}: code #{error.code}, level #{error.level}\n"
          err << "#{error}\n"
          error.str1.present? and err << "#{error.str1}\n"
          error.str2.present? and err << "#{error.str2}\n"
          error.str3.present? and err << "#{error.str3}\n"
          err << xml.lines[error.line - 1].rstrip + "\n"
          error.column > 1 and err << ('-' * (error.column - 1))
          err << "^\n"
          err
        else
          ''
        end
      end

    errs = errs.join("\n")
    errs.present? and raise Minitest::Assertion, errs
  end
  private :_assert_no_xml_or_html_syntax_errors

  ##
  # After calling +assert_xml+ or +assert_html+, or calling a test method that loads
  # +response.body+, call +assert_xpath+ to query XML's or HTML's Document Object
  # Model and interrogate its tags, attributes, and contents.
  #
  # ==== Parameters
  #
  # * +path+ - Required XPath string.
  # * +replacements+ - Optional Hash of replacement keys and values.
  # * +message+ - Optional string or ->{block} containing additional diagnostics.
  # * <code>&block</code> - Optional block to call with a selected context.
  #
  # ==== Returns
  #
  # +assert_xpath+ returns the first <code>Nokogiri::XML::Element</code> it finds matching its
  # XPath, and it yields this element to any block it is called with. Note that Nokogiri
  # supplies many useful methods on this element, including +.text+ to access its text
  # contents, and <code>[]</code> to access its attributes, such as the below
  # <code>form[:method]</code>. And because the method +.to_s+ returns an element's outer
  # HTML, a debugging trace line like <code>puts assert_xpath('td[ 2 ]')</code> will
  # output the selected element's HTML.
  #
  # ==== Yields
  #
  # You may call +assert_select+ and pass it a block containing +assert_xpath+,
  # and +assert_xpath+ optionally yields to a block where you can call +assert_xpath+
  # and +assert_select+. Each block restricts the context which XPath or CSS selectors
  # can access:
  #
  #   get :index
  #   assert_select 'td#contact_form' do
  #     assert_xpath 'form[ "/contact" = @action ]' do |form|
  #       assert_equal 'post', form[:method]
  #       assert_xpath './/input[ "name" = @name and "text" = @type and "" = @value ]'
  #       assert_select 'input[type=submit][name=commit]'
  #     end
  #   end
  #
  # A failure inside one of those +assert_xpath+ blocks will report only its XML or HTML
  # context in its failure messages.
  #
  # ==== Operations
  #
  # Note that an XPath of <code>'form'</code> finds an immediate child of the current
  # context, while a CSS selector of <code>'form'</code> will find any descendant. And
  # note that, although an XPath of <code>'//input'</code> will find any 'input' in
  # the current document, only a relative XPath of <code>'.//input'</code> will find
  # only the descendants of the current context.
  #
  # Warning: At failure time, +assert_xpath+ prints out the XML or HTML context where your
  # XPath failed. However, as a convenience for reading this source, +assert_xpath+ uses
  # Nokogiri to reformat the source, and to expand entities such as <code>&</code>. This
  # means the diagnostic message won't exactly match the input. It's better than nothing.
  #
  # Consult an XPath reference to learn the full power of the queries possible. Here are
  # some examples:
  #
  #   assert_xpath '//select[ "names" = @name and 26 = count( option ) ]' do
  #     assert_xpath 'option[ 1 ][ "Able" = text() ]', 'Must be first.'
  #     assert_xpath 'option[ 2 ][ "Baker" = text() and not( @selected ) ]'
  #     assert_xpath 'option[ 3 ][ "Charlie" = text() and @selected ]'
  #     assert_xpath 'option[ last() ][ "Zed" = text() ]'
  #   end
  #   assert_xpath './/textarea[ "message" = @name and not( text() ) ]'
  #   assert_xpath '/html/head/title[ contains( text(), "Contact us" ) ]'
  #   em = assert_xpath('td/em')
  #   assert_match /No members/, em.text
  #   assert_xpath 'div[ 1 ][ not( * ) ]', 'The first div must have no children.'
  #   assert_xpath '//p[ label[ "type_id" = @for ] ]' # Returns the p not the label
  #
  # +assert_xpath+ accepts a Hash of replacement values for its second or third
  # argument. Use this to inject strings that are long, or contain quotes ' ",
  # or are generated. A Hash key of +:id+ will inject its value into an XPath of
  # <code>$id</code>:
  #
  #   assert_xpath 'label/input[ "radio" = @type and $value = @value and $id = @id ]',
  #                value: type.id, id: "type_id_#{type.id}"
  #
  # Finally, +assert_xpath+ accepts a message string or callable, to provide extra
  # diagnostics in its failure message. This message could be the last argument, but
  # passing the replacements hash last is sometimes more convenient:
  #
  #   assert_xpath 'script[ $amount = @data-amount ]',
  #                'The script must contain a data-amount in pennies',
  #                amount: 100
  #
  # Pass a ->{block} for the message argument if it is expensive and you don't want
  # it to slow down successful tests:
  #
  #   assert_xpath 'script[ $amount = @data-amount ]',
  #                ->{ generate_extra_diagnostics_for_amount(100) },
  #                amount: 100
  #
  def assert_xpath(path, replacements = {}, message = nil, &block)
    replacements, message = _get_xpath_arguments(replacements, message)
    element = @selected.at_xpath(path, nil, replacements)
    element or _flunk_xpath(path, '', replacements, message)

    if block
      begin
        waz_selected = @selected
        @selected = element
        block.call(element)
      ensure
        @selected = waz_selected
      end
    end

    # pass  #  Increment the test runner's assertion count.
    return element
  end

  ##
  # See +assert_xpath+ to learn what contexts can call +refute_xpath+. This
  # assertion fails if the given XPath query can find an element in the current
  # <code>@selected</code> or +response.body+ context.
  #
  # ==== Parameters
  #
  # Like +assert_xpath+ it takes an XPath string, an optional Hash of
  # replacements, and an optional message as a string or callable:
  #
  #   refute_xpath '//form[ $action = @action ]',
  #                { action: "/users/#{user.id}/cancel" },
  #                ->{ 'The Cancel form must not appear yet' }
  #
  # ==== Returns
  #
  # Unlike +assert_xpath+, +refute_xpath+ naturally does not yield to a block
  # or return an element.
  #
  def refute_xpath(path, replacements = {}, message = nil)
    replacements, message = _get_xpath_arguments(replacements, message)
    element = @selected.at_xpath(path, nil, replacements)
    element and _flunk_xpath(path, 'not ', replacements, message)
    # pass  #  Increment the test runner's assertion count.
    return nil  #  there it is; the non-element!
  end

  def _get_xpath_arguments(replacements, message) #:nodoc:
    @selected ||= nil  #  Avoid a dumb warning.
    @selected or assert_html  #  Because assert_html snags response.body for us.
    message_is_replacements = message.is_a?(Hash)
    replacements_is_message = replacements.is_a?(String) || replacements.respond_to?(:call)
    replacements, message = message, replacements if message_is_replacements || replacements_is_message
    #  Nokogiri requires all replacement values to be strings...
    replacements ||= {}
    replacements = replacements.merge(replacements){ |_, _, v| v.to_s }
    return replacements, message
  end
  private :_get_xpath_arguments

  def _flunk_xpath(path, polarity, replacements, message) #:nodoc:
    message = message.respond_to?(:call) ? message.call : message
    diagnostic = message.to_s
    diagnostic.length > 0 and diagnostic << "\n"
    element = Array.wrap(@selected)[0]
    pretty = element.xml? ? element.to_xml : element.to_xhtml
    diagnostic << "Element #{polarity}expected in:\n`#{pretty}`\nat xpath:\n`#{path}`"
    replacements.any? and diagnostic << "\nwith: " + replacements.pretty_inspect
    raise Minitest::Assertion, diagnostic
  end
  private :_flunk_xpath

end