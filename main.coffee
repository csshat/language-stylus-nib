_ = require 'lodash'
{css, utils} = require 'octopus-helpers'


setNumberValue = (number) ->
  converted = parseInt(number, 10)
  if not number.match(/^\d+(\.\d+)?$/)
    return 'Please enter numeric value'
  else
    return converted


_declaration = ($$, cssStyleSyntax, property, value, modifier) ->
  return if not value? or value == ''

  if cssStyleSyntax
    colon = ':'
    semicolon = ';'
  else
    colon = ''
    semicolon = ''

  if modifier
    value = modifier(value)

  $$ "#{property}#{colon} #{value}#{semicolon}"


renderColor = (color, colorVariable) ->
  if color.a < 1
    "fade-out(#{colorVariable}, #{1 - color.a})"
  else
    colorVariable


_comment = ($, showComments, text) ->
  return unless showComments
  $ "// #{text}"

_convertColor = _.partial(css.convertColor, renderColor)


defineVariable = (name, value, options) ->
  semicolon = if options.cssStyleSyntax then ';' else ''
  "#{name} = #{value}#{semicolon}"


renderVariable = (name) -> name


_startSelector = ($, selector, cssStyleSyntax, selectorOptions, text) ->
  return unless selector
  curlyBracket = if cssStyleSyntax then ' {' else ''
  $ '%s%s', utils.prettySelectors(text, selectorOptions), curlyBracket


_endSelector = ($, selector, cssStyleSyntax) ->
  $ '}' if selector and cssStyleSyntax


class Stylus

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $.indents, @options.cssStyleSyntax)
    comment = _.partial(_comment, $, @options.showComments)

    rootValue = switch @options.unit
      when 'px' then 0
      when 'em' then @options.emValue
      when 'rem' then @options.remValue
    unit = _.partial(css.unit, @options.unit, rootValue)

    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(_startSelector, $, @options.selector, @options.cssStyleSyntax, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.selector, @options.cssStyleSyntax)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)
        comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            if @options.enableNib
              if @bounds.left is @bounds.top is 0
                declaration('absolute', "top left")
              else
                declaration('absolute', "top #{unit(@bounds.top)} left #{unit(@bounds.left)}")
            else
              declaration('position', 'absolute')
              declaration('left', @bounds.left, unit)
              declaration('top', @bounds.top, unit)

          if @bounds
            if @options.enableNib
              if @bounds.width == @bounds.height
                declaration('size', @bounds.width, unit)
              else
                declaration('size', "#{unit(@bounds.width)} #{unit(@bounds.height)}")
            else
              declaration('width', @bounds.width, unit)
              declaration('height: ', @bounds.height, unit)

          declaration('opacity', @opacity)
          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      comment("Style for #{utils.trim(@name)}")
      startSelector(@name)

      if @options.showAbsolutePositions
        if @options.enableNib
          if @bounds.left is @bounds.top is 0
            declaration('absolute', "top left")
          else
            declaration('absolute', "top #{unit(@bounds.top)} left #{unit(@bounds.left)}")
        else
          declaration('position', 'absolute')
          declaration('left', @bounds.left, unit)
          declaration('top', @bounds.top, unit)

      if @bounds
        if @options.enableNib
          if @bounds.width == @bounds.height
            declaration('size', @bounds.width, unit)
          else
            declaration('size', "#{unit(@bounds.width)} #{unit(@bounds.height)}")
        else
          declaration('width', @bounds.width, unit)
          declaration('height', @bounds.height, unit)

      declaration('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          gradientStr = css.convertGradients(convertColor, {gradient: @background.gradient, @bounds})
          declaration('background-image', gradientStr) if gradientStr

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      declaration('border-radius', @radius, css.radius)

      if @shadows
        declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports = {defineVariable, renderVariable, setNumberValue, renderClass: Stylus}
