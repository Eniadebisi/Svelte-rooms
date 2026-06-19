'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT
  ? `${process.env.OTEL_EXPORTER_OTLP_ENDPOINT}/v1/traces`
  : 'http://jaeger-collector.observability:4318/v1/traces';

const sdk = new NodeSDK({
  serviceName: process.env.OTEL_SERVICE_NAME || 'svelte-rooms',
  traceExporter: new OTLPTraceExporter({ url: endpoint }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
});
