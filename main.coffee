_ = require 'lodash'
{trimName, selector} = require './helpers'
{css} = require 'octopus-helpers'
{px} = css
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


_fontStyles = (declaration, colorFormat, {font, color}) ->
  declaration('color', colorFormat(color)) if color?

  if font
    declaration('font-family', font.name)
    declaration('font-size', font.size, px)
    declaration('font-weight', font.weight)
    declaration('font-style', font.style)

    if font.underline?
      declaration('text-decoration', 'underline')
    else if font.linethrough?
      declaration('text-decoration', 'line-through')


_colorFormat = (colors, colorType, color) ->
  hexColor = tinycolor(color).toHexString(true)
  colorVariable = colors[hexColor]

  if colorVariable?
    if color.a < 1
      "fade-out(#{colorVariable}, #{1 - color.a})"
    else
      colorVariable
  else
    css.color(color, colorType)


class Stylus

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $.indents, @options.cssStyleSyntax)
    comment = _.partial(_comment, $)
    colorFormat = _.partial(_colorFormat, @options.colors, @options.colorType)
    fontStyles = _.partial(_fontStyles, declaration, colorFormat)

    baseTextComment = 'Base text style'
    textComment = 'Text style for'
    cssComment = 'Style for'

    # This options add explaining comment about CSS code below
    if @options.showTextSnippet
      if @textStyles?
        if @textStyles.length > 1 and @options.inheritFontStyles?
          comment(baseTextStyle)
        else
          comment("#{textComment} #{trimName(@name)}")
      else
        comment("#{cssComment} #{trimName(@name)}")

    # This option add selector according to name of the layer
    if @options.selector
        curlyBracket = if @options.cssStyleSyntax then ' {' else ''
        $ '%s%s', selector(@), curlyBracket

    declaration('opacity', @opacity)

    if @bounds
      if @bounds.width == @bounds.height
        declaration('size', @bounds.width, px)
      else
        declaration('size', "#{px(@bounds.width)} #{px(@bounds.height)}")

    if @options.inheritFontStyles and @baseTextStyle?
      fontStyles(@baseTextStyle)

    if @textStyles?
      fontStyles(textStyle) for textStyle in @textStyles

    if @background
      declaration('background-color', @background.color, colorFormat)

    # Close block code definition if selector option is choosen
    if @options.selector and @options.cssStyleSyntax
        $ '}'


defineVariable = (name, value, options) ->
  semicolon = if options.cssStyleSyntax then ';' else ''
  "#{name} = #{value}#{semicolon}"


renderVariable = (name) -> name


module.exports = {defineVariable, renderVariable, renderClass: Stylus}
