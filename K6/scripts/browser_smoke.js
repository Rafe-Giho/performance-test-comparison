import { browser } from 'k6/browser';
import { check } from 'k6';

function requiredUrl(name) {
  const value = __ENV[name];
  if (value === undefined || value === null || String(value).trim() === '') {
    throw new Error(`Required environment variable is not set: ${name}`);
  }
  if (!/^https?:\/\//.test(value)) {
    throw new Error(`${name} must start with http:// or https://`);
  }
  return value;
}

const BASE_URL = requiredUrl('BASE_URL');

export const options = {
  scenarios: {
    browser: {
      executor: 'shared-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '2m',
      options: {
        browser: {
          type: 'chromium',
        },
      },
    },
  },
  thresholds: {
    checks: ['rate==1.0'],
  },
};

export default async function () {
  const page = await browser.newPage();

  try {
    await page.goto(BASE_URL, { waitUntil: 'networkidle' });
    const title = await page.title();
    check(title, {
      'title exists': (value) => value && value.length > 0,
    });
  } finally {
    await page.close();
  }
}
