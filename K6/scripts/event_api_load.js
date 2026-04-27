import http from 'k6/http';
import { check, group, sleep } from 'k6';

function requiredEnv(name) {
  const value = __ENV[name];
  if (value === undefined || value === null || String(value).trim() === '') {
    throw new Error(`Required environment variable is not set: ${name}`);
  }
  return value;
}

function requiredUrl(name) {
  const value = requiredEnv(name);
  if (!/^https?:\/\//.test(value)) {
    throw new Error(`${name} must start with http:// or https://`);
  }
  return value.replace(/\/+$/, '');
}

const BASE_URL = requiredUrl('BASE_URL');
const USERNAME = requiredEnv('USERNAME');
const PASSWORD = requiredEnv('PASSWORD');
const HEALTH_PATH = requiredEnv('HEALTH_PATH');
const LOGIN_PATH = requiredEnv('LOGIN_PATH');
const LIST_PATH = requiredEnv('LIST_PATH');
const DETAIL_PATH = requiredEnv('DETAIL_PATH');
const EVENT_PATH = requiredEnv('EVENT_PATH');
const EVENT_PAYLOAD = JSON.stringify(JSON.parse(requiredEnv('EVENT_PAYLOAD')));
const JSON_HEADERS = {
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
};

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
    const res = http.post(`${BASE_URL}${LOGIN_PATH}`, payload, JSON_HEADERS);
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

  group('05-event', () => {
    const res = http.post(`${BASE_URL}${EVENT_PATH}`, EVENT_PAYLOAD, JSON_HEADERS);
    check(res, { 'event is 200': (r) => r.status === 200 });
  });

  sleep(1);
}
