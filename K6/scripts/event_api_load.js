import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://example.com';
const USERNAME = __ENV.USERNAME || 'user01';
const PASSWORD = __ENV.PASSWORD || 'pass01';
const HEALTH_PATH = __ENV.HEALTH_PATH || '/health';
const LOGIN_PATH = __ENV.LOGIN_PATH || '/api/login';
const LIST_PATH = __ENV.LIST_PATH || '/api/items';
const DETAIL_PATH = __ENV.DETAIL_PATH || '/api/items/1';

export const options = {
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
  scenarios: {
    baseline: {
      executor: 'ramping-arrival-rate',
      startRate: 1,
      timeUnit: '1s',
      preAllocatedVUs: 20,
      maxVUs: 100,
      stages: [
        { target: 5, duration: '1m' },
        { target: 10, duration: '3m' },
        { target: 0, duration: '30s' },
      ],
    },
    spike: {
      executor: 'constant-arrival-rate',
      startTime: '4m30s',
      rate: 25,
      timeUnit: '1s',
      duration: '30s',
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
};

export default function () {
  group('01-health', () => {
    const res = http.get(`${BASE_URL}${HEALTH_PATH}`);
    check(res, { 'health is 200': (r) => r.status === 200 });
  });

  group('02-login', () => {
    const payload = JSON.stringify({
      username: USERNAME,
      password: PASSWORD,
    });
    const params = {
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
    };
    const res = http.post(`${BASE_URL}${LOGIN_PATH}`, payload, params);
    check(res, { 'login is 200': (r) => r.status === 200 });
  });

  group('03-list', () => {
    const res = http.get(`${BASE_URL}${LIST_PATH}`);
    check(res, { 'list is 200': (r) => r.status === 200 });
  });

  group('04-detail', () => {
    const res = http.get(`${BASE_URL}${DETAIL_PATH}`);
    check(res, { 'detail is 200': (r) => r.status === 200 });
  });

  sleep(1);
}
