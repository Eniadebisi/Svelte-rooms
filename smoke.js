import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000']
  }
};

const BASE = __ENV.BASE_URL || 'http://localhost:3000';

export default function() {
  const r = http.get(BASE + '/health');
  check(r, { 'status 200': (r) => r.status === 200 });
}