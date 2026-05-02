import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: __ENV.VUS ? Number(__ENV.VUS) : 20,
  duration: __ENV.DURATION || '2m',
  thresholds: {
    http_req_duration: ['p(95)<1200'],
    http_req_failed: ['rate<0.02'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TOKEN = __ENV.TOKEN || '';

function authHeaders() {
  const headers = { 'X-Correlation-Id': `k6-${__VU}-${__ITER}` };
  if (TOKEN) headers['Authorization'] = `Bearer ${TOKEN}`;
  return headers;
}

export default function () {
  const payload = 'Invoice perf payload';
  const file = http.file(payload, `invoice-${__VU}-${__ITER}.txt`, 'text/plain');
  const res = http.post(`${BASE_URL}/api/v2/invoices/upload`, { file }, { headers: authHeaders() });

  check(res, {
    'upload accepted or idempotent': (r) => [200, 201, 202].includes(r.status),
  });

  sleep(0.2);
}
