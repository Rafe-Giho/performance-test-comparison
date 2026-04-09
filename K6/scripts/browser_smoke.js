import { browser } from 'k6/browser';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://test.k6.io/';

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
