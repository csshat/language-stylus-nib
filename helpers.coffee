css = require('octopus-helpers').css
utils = require('octopus-helpers').utils

trimName = (value) ->
  value = value.replace(/\s{2,}/, ' ').trim()

  if value.length > 14
    value = value.slice(0, 20).trim()
    value += '…'

  value

selector = ({options, name, type, id}) ->
  dictionary =
    'dash-case': 'dash'
    'camelCase': 'camel'
    'snake_case': 'snake'

  style = dictionary[options.selectorTextStyle] or 'dash'

  switch options.selectorType
    when 'id' then prefix = '#'
    when 'class' then prefix = '.'
    else prefix = ''

  name = utils.format(name, style)

  name = (type.toLowerCase() + id) unless name.length

  prefix + name


# Exports
module.exports = {trimName, selector}
