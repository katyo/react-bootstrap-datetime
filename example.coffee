{render, createClass, createElement} = require "react"
{Panel, ButtonToolbar, Button} = require "react-bootstrap"
#{DateTime} = require "react-bootstrap-datetime"
{DateTime} = require "./lib.coffee"
moment = require "moment"
require "moment/locale/ru"
require "moment/locale/it"
require "moment/locale/fr"

langs =
  en: "English"
  ru: "Russian"
  it: "Italian"
  fr: "French"

Example = createClass
  getInitialState: ->
    locale: "en"
  setLocale: (locale)-> =>
    @setState {locale}
  handleChange: ->
    @setState time: do @refs.time.getValue
  render: ->
    {locale, time} = @state
    createElement Panel,
      header: "Date and time picker"
      createElement ButtonToolbar, null,
        for langCode, langName of langs
          createElement Button,
            key: langCode
            bsStyle: if langCode is locale then "primary" else "link"
            onClick: @setLocale langCode
            langName
      createElement DateTime,
        label: "Simple date and time"
        help: "You can to change date and time here."
        locale: locale
      createElement DateTime,
        label: "Custom display format date"
        help: "Link style without icon."
        datePart: "LL"
        timePart: no
        bsStyle: "link"
        dateGlyph: no
        locale: locale
      createElement DateTime,
        label: "Custom display format time"
        help: "With warning style applied. Current time #{time or "now"}"
        datePart: no
        bsStyle: "warning"
        timePart: "hh:mm A"
        ref: "time"
        onChange: @handleChange
        locale: locale
      createElement DateTime,
        label: "Default 13 Jan 2008"
        help: "Drop up with succes style."
        bsStyle: "success"
        defaultValue: "01/13/2008"
        format: "MM/DD/YYYY"
        datePart: "MM/DD/YY"
        timePart: no
        dropup: yes
        locale: locale
      createElement DateTime,
        label: "Limited date and time"
        help: "Date and time in localized format from 01.01.2015 to 31.12.2017 with default 10.01.2015 12:30:00."
        bsStyle: "danger"
        locale: locale
        datePart: "LL"
        timePart: "hh:mm:ss A"
        defaultValue: "10.01.2015 12:30:00"
        format: "DD.MM.YYYY HH:mm:ss"
        minValue: "01.01.2015"
        maxValue: "31.12.2017"

render (createElement Example), document.getElementById "example"
