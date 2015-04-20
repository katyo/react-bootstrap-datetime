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
    moment.locale "en"
    lang: "en"
  setLocale: (lang)-> =>
    moment.locale lang
    @setState {lang}
  render: ->
    {lang} = @state
    createElement Panel,
      header: "Date and time picker"
      createElement ButtonToolbar, null,
        for langCode, langName of langs
          createElement Button,
            key: langCode
            bsStyle: if langCode is lang then "primary" else "link"
            onClick: @setLocale langCode
            langName
      createElement DateTime,
        label: "Simple date and time"
        help: "You can to change date and time here."
      createElement DateTime,
        label: "Custom display format date"
        help: "Link styte without caret."
        datePart: "LL"
        timePart: no
        bsStyle: "link"
        noCaret: yes
      createElement DateTime,
        label: "Custom display format time"
        help: "With warning style applied."
        datePart: no
        bsStyle: "warning"
        timePart: "hh:mm A"
      createElement DateTime,
        label: "Default 13 Jan 2008"
        help: "Drop up with succes style."
        bsStyle: "success"
        defaultValue: "01/13/2008"
        format: "MM/DD/YYYY"
        datePart: "MM/DD/YY"
        timePart: no
        dropup: yes

render (createElement Example), document.getElementById "example"
