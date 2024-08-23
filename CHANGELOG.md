# Changelog for Tracing v0.1 

## 0.1.5 (2024-08-23)

* Add option to handle expected failurs in `ObanTelemetry` by allowing `reportable?/1` to be set in Oban workers

## 0.1.4 (2024-07-12)

* Add `Tracing.set_current_span/1` function
* Add `Tracing.monitor/1` as shorthand for `Tracing.Monitor.monitor/1`
    * Allow `Tracing.monitor/0` to call Monitor for the current span
* Make use of internal Tracing functions

## 0.1.3 (2024-06-28)

* Add `LiveviewTelemetry` telemetry module
  * add setup option `:liveview`

## 0.1.2 (2024-06-20)

* Fix wrong call when monitor option is passed into `with_span_fn/3`, call `Tracing.Monitor.monitor` instead of
  `Tracing.monitor`

## 0.1.1 (2024-06-19)

* Update telemetry_metrics to 1.0.0

## 0.1.0 (2024-06-12)

* Add `Tracing.Monitor`
* Remove `OpenTelemetryPhoenixLiveView`
* Rename project (`OT`) to `Tracing`

## 0.1.0 (2024-04-26)

* Add `OpenTelemetryPhoenix`
* Add `OpenTelemetryPhoenixLiveView`
* Add `Decorator`
* Add `Sampler`
* Add telemetry modules
    * Add `AWSTelemetry`
    * Add `ObanTelemetry`
    * Add `ChromicPDFTelemetry`

