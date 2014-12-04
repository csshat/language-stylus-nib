_ = require 'lodash'
{trimName, selector} = require './helpers'
{css} = require 'octopus-helpers'
tinycolor = require 'tinycolor2'


_declaration = ($$, cssStyleSyntax, property, value, modifier) ->
  return unless value?

  if cssStyleSyntax
    colon = ':'
    semicolon = ';'
  else
    colon = ''
    semicolon = ''

  if modifier
    value = modifier(value)

  $$ "#{property}#{colon} #{value}#{semicolon}"


_comment = ($, text) ->
  $ "// #{text}"


_convertColor = _.partial(css.convertColor, renderColor)


renderColor = (color, colorVariable) ->
  if color.a < 1
    "fade-out(#{colorVariable}, #{1 - color.a})"
  else
    colorVariable


defineVariable = (name, value, options) ->
  semicolon = if options.cssStyleSyntax then ';' else ''
  "#{name} = #{value}#{semicolon}"


renderVariable = (name) -> name


class Stylus

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $.indents, @options.cssStyleSyntax)
    comment = _.partial(_comment, $)
    unit = _.partial(css.unit, 'px')
    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, "'")

    baseTextComment = 'Base text style'
    textComment = 'Text style for'
    cssComment = 'Style for'

    # This options add explaining comment about CSS code below
    if @options.showTextSnippet
      if @textStyles?
        if @textStyles.length > 1 and @options.inheritFontStyles?
          comment(baseTextComment)
        else
          comment("#{textComment} #{trimName(@name)}")
      else
        comment("#{cssComment} #{trimName(@name)}")

    # This option add selector according to name of the layer
    if @options.selector
      curlyBracket = if @options.cssStyleSyntax then ' {' else ''
      $ '%s%s', selector(@), curlyBracket

    declaration('opacity', @opacity)

    if @type != 'textLayer' and @bounds
      if @bounds.width == @bounds.height
        declaration('size', @bounds.width, unit)
      else
        declaration('size', "#{unit(@bounds.width)} #{unit(@bounds.height)}")

    if @options.inheritFontStyles and @baseTextStyle?
      fontStyles(@baseTextStyle)

    if @textStyles?
      fontStyles(textStyle) for textStyle in @textStyles

    if @background
      declaration('background-color', @background.color, convertColor)

    if @borders
      border = @borders[0]
      declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

    declaration('border-radius', @radius, css.radius)

    if @shadows
      if @type == 'textLayer'
        declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))
      else
        declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

    # Close block code definition if selector option is choosen
    if @options.selector and @options.cssStyleSyntax
        $ '}'


module.exports = {defineVariable, renderVariable, renderClass: Stylus}
