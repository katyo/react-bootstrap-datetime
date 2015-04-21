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
    locale: PropTypes.string
    minValue: PropTypes.string
    maxValue: PropTypes.string
  
  getDefaultProps: ->
    locale: do moment.locale
    format: defaultFormat
    defaultValue: (do moment).format defaultFormat
    minValue: no
    maxValue: no
  
  getInitialState: ->
    {value, defaultValue, locale} = @props
    @setLocale? locale if locale?
    value ?= defaultValue
    {value}

  applyLimits: (value, minValue, maxValue)->
    minValue ?= @props.minValue
    maxValue ?= @props.maxValue
    value ?= @state.value
    if minValue or maxValue
      {format} = @props
      value = moment value, format
      value = minValue if minValue and value.isBefore (minValue = moment minValue, format)
      value = maxValue if maxValue and value.isAfter (maxValue = moment maxValue, format)
      value.format format
    else
      value

  supUnits:
    year: null
    month: "year"
    date: "month"
    hour: "date"
    minute: "hour"
    second: "minute"

  isSameBase: (units, value1, value2)->
    supUnits = @supUnits[units]
    not supUnits? or (value1.get supUnits) == (value2.get supUnits) and @isSameBase supUnits, value1, value2
  
  getLimits: (units)->
    {format, minValue, maxValue} = @props
    datetime = do @getMoment
    [
      minValue.get units if minValue and @isSameBase units, datetime, minValue = moment minValue, format
      maxValue.get units if maxValue and @isSameBase units, datetime, maxValue = moment maxValue, format
    ]
  
  componentWillReceiveProps: ({value, locale, minValue, maxValue})->
    value = @applyLimits value, minValue, maxValue
    # We need update value in state only when it differs from existing value
    @setValue value, no
    # We need reconfigure locale when it changed
    @setLocale? locale if locale? and locale isnt @props.locale
  
  setValue: (value, update = yes)->
    {onChange} = @props
    # Set new value and call onChange handler
    if value?
      if value isnt @state.value
        @setState {value}, (onChange if update)
      else
        do onChange if update and onChange
  
  modifyValue: (fn)->
    datetime = do @getMoment
    fn.call datetime
    @setValue @applyLimits datetime.format @props.format
  
  parseFormat: (format)->
    format.split formatRegex
  
  getMoment: ->
    {format, locale} = @props
    {value} = @state
    datetime = moment value, format
    datetime.locale locale if locale
    datetime
  
  getValue: ->
    @state.value

  wheelValue: (e, p, n = 1)->
    do e.preventDefault
    delta = e.deltaY or e.deltaX
    delta /= -Math.abs delta
    delta *= n
    @modifyValue -> @add delta, p

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
    @modifyValue -> @year year
  
  render: ->
    datetime = do @getMoment
    
    {yearsRange} = @props
    {yearsOffset} = @state
    [minYear, maxYear] = @getLimits "year"
    
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
                    disabled: minYear? and year < minYear or maxYear? and year > maxYear
                    year

MonthPicker = createClass
  mixins: [
    PickerMixin
  ]
  
  pickMon: (mon)-> =>
    @modifyValue -> @month mon
  
  setLocale: (locale)->
    datetime = do moment
    datetime.locale locale
    @monthName = ((datetime.month month).format "MMMM" for month in [0...12])
  
  render: ->
    datetime = do @getMoment

    activeMonth = do datetime.month
    [minMonth, maxMonth] = @getLimits "month"

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
                  disabled: minMonth? and month < minMonth or maxMonth? and month > maxMonth
                  @monthName[month]

DatePicker = createClass
  mixins: [
    PickerMixin
  ]
  
  prevMon: -> @modifyValue -> @subtract 1, "M"
    
  nextMon: -> @modifyValue -> @add 1, "M"

  wheelMon: (e)-> @wheelValue e, "M", -1

  wheelYear: (e)-> @wheelValue e, "Y", -1
  
  pickDate: (date)-> =>
    @modifyValue -> @date date

  setLocale: (locale)->
    datetime = do moment
    datetime.locale locale
    @weekdayName = ((datetime.weekday weekday).format "ddd" for weekday in [0...7])
  
  render: ->
    {onClickYear, onClickMonth} = @props
    datetime = do @getMoment

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

    [minDate, maxDate] = @getLimits "date"
    
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
              onWheel: @wheelYear
              onClick: onClickYear
              datetime.format "YYYY"
          th
            colSpan: 3
            style:
              textAlign: "center"
            createElement Button,
              bsStyle: "link"
              onWheel: @wheelMon
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
              @weekdayName[day]
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
                    disabled: minDate? and date < minDate or maxDate? and date > maxDate
                    date

TimePicker = createClass
  mixins: [
    PickerMixin
  ]
  
  getDefaultProps: ->
    display: "HH:mm:ss"

  prevHour: -> @modifyValue -> @subtract 1, "h"
  nextHour: -> @modifyValue -> @add 1, "h"
  wheelHour: (e)-> @wheelValue e, "h"

  prevMin: -> @modifyValue -> @subtract 1, "m"
  nextMin: -> @modifyValue -> @add 1, "m"
  wheelMin: (e)-> @wheelValue e, "m"
  

  prevSec: -> @modifyValue -> @subtract 1, "s"
  nextSec: -> @modifyValue -> @add 1, "s"
  wheelSec: (e)-> @wheelValue e, "s"
  toggleAPM: -> @modifyValue -> if 12 >= do @hour then @add 12, "h" else @subtract 12, "h"
  
  render: ->
    datetime = do @getMoment
    tokens = @parseFormat @props.display

    [minHour, maxHour] = @getLimits "hour"
    [minMin, maxMin] = @getLimits "minute"
    [minSec, maxSec] = @getLimits "second"

    hour = do datetime.hour
    min = do datetime.minute
    sec = do datetime.second
    
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
                    disabled: maxHour? and hour >= maxHour
                    createElement Glyphicon,
                      glyph: "chevron-up"
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @nextMin
                    disabled: maxMin? and min >= maxMin
                    createElement Glyphicon,
                      glyph: "chevron-up"
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @nextSec
                    disabled: maxSec? and sec >= maxSec
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
                    onWheel: @wheelHour
                    datetime.format token
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onWheel: @wheelMin
                    datetime.format token
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onWheel: @wheelSec
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
                    disabled: minHour? and hour <= minHour
                    createElement Glyphicon,
                      glyph: "chevron-down"
                when /^m/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @prevMin
                    disabled: minMin? and min <= minMin
                    createElement Glyphicon,
                      glyph: "chevron-down"
                when /^s/.test token
                  createElement Button,
                    bsStyle: "link"
                    onClick: @prevSec
                    disabled: minSec? and sec <= minSec
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
    {label, help, addonBefore, addonAfter, format, datePart, timePart, dateGlyph, timeGlyph, dropup, bsStyle, locale, minValue, maxValue} = @props
    {value, dateView} = @state
    datetime = do @getMoment
    
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
                  locale: locale
                  format: format
                  onChange: @handleDay
                  onClickYear: @viewYears
                  onClickMonth: @viewMonths
                  value: value
                  minValue: minValue
                  maxValue: maxValue
              createElement MenuItem,
                style:
                  display: if "months" is dateView then "block" else "none"
                header: yes
                createElement MonthPicker,
                  ref: "month"
                  locale: locale
                  format: format
                  onChange: @handleMonth
                  value: value
                  minValue: minValue
                  maxValue: maxValue
              createElement MenuItem,
                style:
                  display: if "years" is dateView then "block" else "none"
                header: yes
                createElement YearPicker,
                  ref: "year"
                  locale: locale
                  format: format
                  onChange: @handleYear
                  value: value
                  minValue: minValue
                  maxValue: maxValue
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
                  locale: locale
                  format: format
                  display: timePart
                  onChange: @handleTime
                  value: value
                  minValue: minValue
                  maxValue: maxValue

module.exports = {
  PickerMixin
  YearPicker
  MonthPicker
  DatePicker
  TimePicker
  DateTime
}
