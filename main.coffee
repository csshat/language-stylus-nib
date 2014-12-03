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


_textDecoration = (font) ->
  textDecoration = []

  if font.underline
    textDecoration.push('underline')

  if font.linethrough
    textDecoration.push('line-through')

  textDecoration


_convertFontStyleName = (fontType) ->
  fontStyles = css.fontStyleNameToCSS(fontType)

  ret = {}
  ret[fontStyle.property] = fontStyle.value for fontStyle in fontStyles
  ret


_fontStyles = (declaration, colorFormat, {font, color}) ->
  declaration('color', colorFormat(color)) if color?

  if font
    font = _.assign(font, _convertFontStyleName(font.type)) if font.type

    declaration('font-family', font.name)
    declaration('font-size', font.size, px)
    declaration('font-weight', font.weight)
    declaration('font-style', font.style)
    declaration('line-height', font.lineHeight, px)
    declaration('letter-spacing', font.letterSpacing, px)

    textDecoration = _textDecoration(font)
    if textDecoration.length
      declaration('text-decoration', textDecoration.join(' '))

    if font.uppercase
      declaration('text-transform', 'uppercase')

    if font.smallcaps
      declaration('font-variant', 'small-caps')


_getColorVariable = (useColorName, colorVariables, color) ->
  colorObj = tinycolor(color)
  hexColor = colorObj.toHexString(true)
  colorVariable = colorVariables[hexColor]

  if not colorVariable and useColorName
    colorVariable = colorObj.toName()

  colorVariable


colorFormat = (renderColor, options, color) ->
  colorVariable = _getColorVariable(options.useColorName, options.colors, color)
  if colorVariable
    renderColor(color, colorVariable)
  else
    css.color(color, options.colorType)


renderColor = (color, colorVariable) ->
  if color.a < 1
    "fade-out(#{colorVariable}, #{1 - color.a})"
  else
    colorVariable


_colorFormat = _.partial(css.colorFormat, renderColor)


class Stylus

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $.indents, @options.cssStyleSyntax)
    comment = _.partial(_comment, $)
    colorFormat = _.partial(_colorFormat, @options)
    fontStyles = _.partial(_fontStyles, declaration, colorFormat)

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
