{
  createClass
  createElement
  createFactory
  DOM: {
    table
    thead
    tbody
    th
    tr
    td
  }
  PropTypes
} = require "react"

{
  Input
  ButtonToolbar
  ButtonGroup
  Button
  DropdownButton
  MenuItem
  Table
  Glyphicon
} = require "react-bootstrap"

moment = require "moment"
{defaultFormat} = moment

formatRegex = /([QeEAaXx]|M{1,4}o?|D{1,4}o?|d{1,4}o?|w{1,2}o?|W{1,2}o?|Y{2,4}|g{2,4}|G{2,4}|H{1,2}|h{1,2}|m{1,2}|s{1,2}|S{1,3}|z{1,2}|Z{1,2})/

PickerMixin =
  propTypes: ->
    format: PropTypes.string
    value: PropTypes.string
    defaultValue: PropTypes.string
  
  getDefaultProps: ->
    format: defaultFormat
    defaultValue: (do moment).format defaultFormat
  
  getInitialState: ->
    {value, defaultValue} = @props
    value ?= defaultValue
    {value}
  
  componentWillReceiveProps: ({value})->
    # We need update value in state only when it differs from existing value
    @setState {value} if value? and value isnt @state.value

  setValue: (value)->
    # Set new value and call onChange handler
    @setState {value}, @props.onChange if value? and value isnt @state.value
  
  changeValue: (fn)->
    {format, onChange} = @props
    {value} = @state
    date = moment value, format
    fn.call date
    @setValue date.format format
  
  parseFormat: (format)->
    format.split formatRegex
  
  moment: ->
    {format} = @props
    {value} = @state
    moment value, format
  
  getValue: ->
    @state.value

  tune: (e, p, n = 1)->
    do e.preventDefault
    delta = e.deltaY or e.deltaX
    delta /= -Math.abs delta
    delta *= n
    @changeValue -> @add delta, p

YearPicker = createClass
  mixins: [
    PickerMixin
  ]
  
  getDefaultProps: ->
    yearsRange: [-12, 12]

  getInitialState: ->
    yearsOffset: 0
  
  pageYears: (page)->
    {yearsRange} = @props
    {yearsOffset} = @state
    yearsOffset += page * (yearsRange[1] - yearsRange[0])
    @setState {yearsOffset} 

  prevYears: ->
    @pageYears -1

  nextYears: ->
    @pageYears 1
  
  pickYear: (year)-> =>
    @changeValue -> @year year
    @setState view: "days"
  
  render: ->
    datetime = do @moment
    
    {yearsRange} = @props
    {yearsOffset} = @state

    activeYear = do datetime.year
    baseYear = activeYear + yearsOffset
    firstYear = yearsRange[0] + baseYear
    lastYear = yearsRange[1] + baseYear
    years = yearsRange[1] - yearsRange[0] + 1
    cols = Math.ceil Math.sqrt years
    rows = Math.ceil years / cols
    
    table null,
      thead null,
        tr null,
          th
            colSpan: cols - 1
            createElement Button,
              bsStyle: "link"
              onClick: @prevYears
              createElement Glyphicon,
                glyph: "chevron-left"
          th
            className: "pull-right"
            createElement Button,
              bsStyle: "link"
              onClick: @nextYears
              createElement Glyphicon,
                glyph: "chevron-right"
      tbody null,
        for row in [0...rows]
          tr
            key: row
            for col in [0...cols]
              year = firstYear + row * cols + col
              td
                key: col
                if year <= lastYear
                  createElement Button,
                    bsStyle: if year is activeYear then "primary" else "link"
                    onClick: @pickYear year
                    year

MonthPicker = createClass
  mixins: [
    PickerMixin
  ]
  
  pickMon: (mon)-> =>
    @changeValue -> @month mon
  
  render: ->
    datetime = do @moment

    activeMonth = do datetime.month

    cols = 3
    rows = 4

    table null,
      tbody null,
        for row in [0...rows]
          tr
            key: row
            for col in [0...cols]
              month = row * cols + col
              td
                key: col
                createElement Button,
                  bsStyle: if month is activeMonth then "primary" else "link"
                  onClick: @pickMon month
                  (moment month + 1, "M").format "MMMM"

DatePicker = createClass
  mixins: [
    PickerMixin
  ]
  
  prevMon: -> @changeValue -> @subtract 1, "M"
    
  nextMon: -> @changeValue -> @add 1, "M"

  tuneMon: (e)-> @tune e, "M", -1

  tuneYear: (e)-> @tune e, "Y", -1
  
  pickDate: (date)-> =>
    @changeValue -> @date date
  
  render: ->
    {onClickYear, onClickMonth} = @props
    datetime = do @moment

    activeDate = do datetime.date
    monthDays = do datetime.daysInMonth

    firstWeek = do ((do datetime.clone).date 1).week
    lastWeek = do ((do datetime.clone).date monthDays).week
    lastWeekIsFirst = no

    if lastWeek < firstWeek
      lastWeekIsFirst = yes
      lastDay = monthDays
      while lastWeek < firstWeek
        lastWeek = do ((do datetime.clone).date lastDay).week
        lastDay -= 1
      lastWeek += 1
    
    firstDay = do ((do datetime.clone).date 1).weekday
    lastDay = do ((do datetime.clone).date monthDays).weekday
    
    table
      key: "days"
      thead null,
        tr null,
          th null,
            createElement Button,
              bsStyle: "link"
              onClick: @prevMon
              createElement Glyphicon,
                glyph: "chevron-left"
          th
            colSpan: 3
            style:
              textAlign: "center"
            createElement Button,
              bsStyle: "link"
              onWheel: @tuneYear
              onClick: onClickYear
              datetime.format "YYYY"
          th
            colSpan: 3
            style:
              textAlign: "center"
            createElement Button,
              bsStyle: "link"
              onWheel: @tuneMon
              onClick: onClickMonth
              datetime.format "MMMM"
          th null,
            createElement Button,
              bsStyle: "link"
              onClick: @nextMon
              createElement Glyphicon,
                glyph: "chevron-right"
      tbody null,
        tr null,
          th null
          for day in [0...7]
            th
              key: day
              style:
                textAlign: "center"
              (moment day, "e").format "ddd"
        for week in [firstWeek..lastWeek]
          tr
            key: week
            th null,
              week
              #if week is lastWeek and lastWeekIsFirst then 1 else week
            for day in [0...7]
              date = (week - firstWeek) * 7 + day - firstDay + 1
              td
                key: day
                if (week isnt firstWeek or day >= firstDay) and (week isnt lastWeek or day <= lastDay)
                  createElement Button,
                    bsStyle: if date is activeDate then "primary" else "link"
                    onClick: @pickDate date
                    date

TimePicker = createClass
  mixins: [
    PickerMixin
  ]
  
  getDefaultProps: ->
    display: "HH:mm:ss"

  prevHour: -> @changeValue -> @subtract 1, "h"
  nextHour: -> @changeValue -> @add 1, "h"
  tuneHour: (e)-> @tune e, "h"

  prevMin: -> @changeValue -> @subtract 1, "m"
  nextMin: -> @changeValue -> @add 1, "m"
  tuneMin: (e)-> @tune e, "m"
  
  prevSec: -> @changeValue -> @subtract 1, "s"
  nextSec: -> @changeValue -> @add 1, "s"
  tuneSec: (e)-> @tune e, "s"

  toggleAPM: -> @changeValue -> if 12 >= do @hour then @add 12, "h" else @subtract 12, "h"
  
  render: ->
    datetime = do @moment
    tokens = @parseFormat @props.display
    
    table null,
      tbody null,
        tr null,
          for token, index in tokens
            td
              key: index
              switch
                when /^[Hh]/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @nextHour
                    createElement Glyphicon,
                      glyph: "chevron-up"
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @nextMin
                    createElement Glyphicon,
                      glyph: "chevron-up"
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @nextSec
                    createElement Glyphicon,
                      glyph: "chevron-up"
        tr null,
          for token, index in tokens
            td
              key: index
              switch
                when /^[Hh]/.test token
                  createElement Button,
                    bsStyle: "link"
                    onWheel: @tuneHour
                    datetime.format token
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onWheel: @tuneMin
                    datetime.format token
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onWheel: @tuneSec
                    datetime.format token
                when /^[aA]/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @toggleAPM
                    datetime.format token
                else
                  token
        tr null,
          for token, index in tokens
            td
              key: index
              switch
                when /^[Hh]/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @prevHour
                    createElement Glyphicon,
                      glyph: "chevron-down"
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @prevMin
                    createElement Glyphicon,
                      glyph: "chevron-down"
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @prevSec
                    createElement Glyphicon,
                      glyph: "chevron-down"

DateTime = createClass
  mixins: [
    PickerMixin
  ]
  
  propTypes: ->
    label: PropTypes.string
    help: PropTypes.string
  
  getDefaultProps: ->
    datePart: "YYYY-MM-DD"
    timePart: "HH:mm:ss"
    dateGlyph: "calendar"
    timeGlyph: "time"
  
  getInitialState: ->
    dateView: "days"
  
  viewDays: ->
    @setState dateView: "days"

  viewYears: ->
    @setState dateView: "years"

  viewMonths: ->
    @setState dateView: "months"

  updateValue: (field)->
    @setValue do @refs[field].getValue

  handleYear: ->
    @updateValue "year"
    do @viewDays
  
  handleMonth: ->
    @updateValue "month"
    do @viewDays
  
  handleDay: ->
    @updateValue "day"
  
  handleTime: ->
    @updateValue "time"
  
  render: ->
    {label, help, addonBefore, addonAfter, format, datePart, timePart, dateGlyph, timeGlyph, dropup, bsStyle} = @props
    {value, dateView} = @state
    datetime = moment value, format
    
    createElement Input, {label, help, addonBefore, addonAfter},
      createElement ButtonToolbar, null,
        createElement ButtonGroup, null,
          if datePart
            createElement DropdownButton,
              noCaret: yes
              dropup: dropup
              bsStyle: bsStyle
              title: [
                datetime.format datePart
                if dateGlyph
                  " "
                if dateGlyph
                  createElement Glyphicon,
                    key: "glyph"
                    glyph: dateGlyph
              ]
              createElement MenuItem,
                style:
                  display: if "days" is dateView then "block" else "none"
                header: yes
                createElement DatePicker,
                  ref: "day"
                  format: format
                  onChange: @handleDay
                  onClickYear: @viewYears
                  onClickMonth: @viewMonths
                  value: value
              createElement MenuItem,
                style:
                  display: if "months" is dateView then "block" else "none"
                header: yes
                createElement MonthPicker,
                  ref: "month"
                  format: format
                  onChange: @handleMonth
                  value: value
              createElement MenuItem,
                style:
                  display: if "years" is dateView then "block" else "none"
                header: yes
                createElement YearPicker,
                  ref: "year"
                  format: format
                  onChange: @handleYear
                  value: value
          if timePart
            createElement DropdownButton,
              noCaret: yes
              dropup: dropup
              bsStyle: bsStyle
              title: [
                datetime.format timePart
                if timeGlyph
                  " "
                if timeGlyph
                  createElement Glyphicon,
                    key: "glyph"
                    glyph: timeGlyph
              ]
              createElement MenuItem,
                header: yes
                createElement TimePicker,
                  ref: "time"
                  format: format
                  display: timePart
                  onChange: @handleTime
                  value: value

module.exports = {
  PickerMixin
  YearPicker
  MonthPicker
  DatePicker
  TimePicker
  DateTime
}
