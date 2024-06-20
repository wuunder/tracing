# Changelog for Tracing v0.1 

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

