#!/usr/bin/env node
// Browser smoke checks against a running Protein Forge server.
const assert = require('node:assert/strict');

process.env.PLAYWRIGHT_BROWSERS_PATH ||= '/workspace/.cache/ms-playwright';
const { chromium } = require('playwright');

const baseURL = process.env.PROTEIN_FORGE_TEST_URL || 'http://127.0.0.1:8000';
const browserErrors = [];

function watchErrors(page, expectedFailurePaths = []) {
  page.on('pageerror', (error) => browserErrors.push(error.message));
  page.on('console', (message) => {
    if (message.type() !== 'error') return;
    const expectedFailure = expectedFailurePaths.some((path) => message.location().url.endsWith(path))
      && message.text().includes('503');
    if (!expectedFailure) browserErrors.push(message.text());
  });
}

async function beginGame(page, selector = '#start-button') {
  const responsePromise = page.waitForResponse((response) =>
    new URL(response.url()).pathname === '/api/game' && response.status() === 200);
  await page.locator(selector).click();
  const game = await (await responsePromise).json();
  await page.locator('#game-screen').waitFor({ state: 'visible' });
  assert.equal(game.questions.length, 6);
  return game.questions;
}

async function score(page) {
  return Number(await page.locator('#score-value').innerText());
}

async function choose(page, code) {
  await page.locator(`.answer-button[data-code="${code}"]`).click();
}

async function checkReference(page) {
  await page.locator('[data-open-reference]').first().click();
  await page.locator('#reference-dialog').waitFor({ state: 'visible' });
  await page.waitForFunction(() => document.querySelectorAll('#codon-table-body tr').length === 64);
  assert.equal(await page.locator('#codon-table-body tr').count(), 64);

  await page.locator('#codon-search').fill('AUG');
  await page.waitForFunction(() => document.querySelectorAll('#codon-table-body tr').length === 1);
  assert.match(await page.locator('#codon-table-body').innerText(), /Metionin/);
  await page.locator('#codon-search').fill('stop');
  await page.waitForFunction(() => document.querySelectorAll('#codon-table-body tr').length === 3);
  for (const codon of ['UAA', 'UAG', 'UGA']) {
    assert.match(await page.locator('#codon-table-body').innerText(), new RegExp(codon));
  }
  await page.keyboard.press('Escape');
  await page.locator('#reference-dialog').waitFor({ state: 'hidden' });
}

async function desktopFlow(browser) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  watchErrors(page);
  await page.goto(baseURL, { waitUntil: 'networkidle' });
  await page.locator('#welcome-screen').waitFor({ state: 'visible' });
  await page.screenshot({ path: '/tmp/protein-forge-desktop.png', fullPage: true, animations: 'disabled' });
  await checkReference(page);

  const questions = await beginGame(page);
  const wrong = questions[0].options.find((option) => option.code !== questions[0].answer).code;
  await choose(page, wrong);
  await page.locator('#feedback.is-error').waitFor({ state: 'visible' });
  assert.equal(await score(page), 0);
  assert.equal(await page.locator('#peptide-chain .chain-node.is-filled').count(), 0);

  for (let index = 0; index < questions.length; index += 1) {
    const question = questions[index];
    assert.match(await page.locator('#round-label').innerText(), new RegExp(`${index + 1}\\s*/\\s*6`));
    await choose(page, question.answer);
    await page.locator('#feedback.is-success').waitFor({ state: 'visible' });
    assert.equal(await score(page), 50 + index * 100);
    assert.equal(await page.locator('#peptide-chain .chain-node.is-filled').count(), Math.min(index + 1, 5));
    const correctButton = page.locator(`.answer-button[data-code="${question.answer}"]`);
    assert.equal(await correctButton.isDisabled(), true, 'Resolved choices must prevent duplicate scoring');
    if (index === 1) {
      await page.screenshot({ path: '/tmp/protein-forge-game.png', fullPage: true, animations: 'disabled' });
    }
    await page.locator('#next-button').click();
  }

  await page.locator('#result-screen').waitFor({ state: 'visible' });
  assert.match(await page.locator('#final-score').innerText(), /550\s*\/\s*600/);
  assert.match(await page.locator('#final-accuracy').innerText(), /5\s*\/\s*6/);
  assert.equal(await page.locator('#final-chain .result-residue').count(), 5);
  assert.doesNotMatch(await page.locator('#final-chain').innerText(), /\*/);
  await page.screenshot({ path: '/tmp/protein-forge-result.png', fullPage: true, animations: 'disabled' });

  await beginGame(page, '#restart-button');
  assert.equal(await score(page), 0);
  assert.equal(await page.locator('#peptide-chain .chain-node.is-filled').count(), 0);
  assert.match(await page.locator('#round-label').innerText(), /1\s*\/\s*6/);
  await page.reload({ waitUntil: 'networkidle' });
  await beginGame(page);
  assert.equal(Number(await page.locator('#best-score-value').innerText()), 550);
  await context.close();
}

async function retryFlow(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();
  watchErrors(page, ['/api/game']);
  let failNextRequest = true;
  await page.route('**/api/game', async (route) => {
    if (failNextRequest) {
      failNextRequest = false;
      await route.fulfill({ status: 503, contentType: 'application/json', body: '{"error":"Uji kegagalan sementara"}' });
    } else {
      await route.continue();
    }
  });
  await page.goto(baseURL);
  await page.locator('#start-button').click();
  await page.locator('#start-error').waitFor({ state: 'visible' });
  assert.ok((await page.locator('#start-error').innerText()).trim());
  assert.equal(await page.locator('#start-button').isEnabled(), true);
  await beginGame(page);
  assert.equal(await score(page), 0);
  await context.close();
}

async function referenceRetryFlow(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();
  watchErrors(page, ['/api/codons']);
  let failNextRequest = true;
  await page.route('**/api/codons', async (route) => {
    if (failNextRequest) {
      failNextRequest = false;
      await route.fulfill({ status: 503, contentType: 'application/json', body: '{}' });
    } else {
      await route.continue();
    }
  });
  await page.goto(baseURL);
  await page.locator('[data-open-reference]').first().click();
  await page.locator('#reference-retry').waitFor({ state: 'visible' });
  assert.match(await page.locator('#reference-status').innerText(), /belum berhasil/);
  await page.locator('#reference-retry').click();
  await page.waitForFunction(() => document.querySelectorAll('#codon-table-body tr').length === 64);
  assert.equal(await page.locator('#reference-retry').isVisible(), false);
  await context.close();
}

async function storageFallbackFlow(browser) {
  const context = await browser.newContext();
  await context.addInitScript(() => {
    Storage.prototype.getItem = () => { throw new DOMException('Storage denied', 'SecurityError'); };
    Storage.prototype.setItem = () => { throw new DOMException('Storage denied', 'SecurityError'); };
  });
  const page = await context.newPage();
  watchErrors(page);
  await page.goto(baseURL);
  const questions = await beginGame(page);
  assert.equal(Number(await page.locator('#best-score-value').innerText()), 0);
  for (const question of questions) {
    await choose(page, question.answer);
    await page.locator('#next-button').click();
  }
  await page.locator('#result-screen').waitFor({ state: 'visible' });
  assert.match(await page.locator('#final-score').innerText(), /600\s*\/\s*600/);
  await context.close();

  const corruptContext = await browser.newContext();
  await corruptContext.addInitScript(() => localStorage.setItem('protein-forge-best-score', 'not-a-score'));
  const corruptPage = await corruptContext.newPage();
  watchErrors(corruptPage);
  await corruptPage.goto(baseURL);
  await beginGame(corruptPage);
  assert.equal(Number(await corruptPage.locator('#best-score-value').innerText()), 0);
  await corruptContext.close();
}

async function mobileFlow(browser) {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const page = await context.newPage();
  watchErrors(page);
  await page.goto(baseURL, { waitUntil: 'networkidle' });
  assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'Landing page overflows mobile viewport');
  await page.screenshot({ path: '/tmp/protein-forge-mobile.png', fullPage: true, animations: 'disabled' });
  const questions = await beginGame(page);
  assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'Game overflows mobile viewport');
  const index = questions[0].options.findIndex((option) => option.code === questions[0].answer);
  await page.keyboard.press(String(index + 1));
  await page.locator('#feedback.is-success').waitFor({ state: 'visible' });
  assert.equal(await score(page), 100);
  await page.locator('#next-button').click();
  assert.match(await page.locator('#round-label').innerText(), /2\s*\/\s*6/);
  await checkReference(page);
  await context.close();
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    await desktopFlow(browser);
    await retryFlow(browser);
    await referenceRetryFlow(browser);
    await storageFallbackFlow(browser);
    await mobileFlow(browser);
    assert.deepEqual(browserErrors, [], 'Unexpected browser errors');
    console.log('Browser checks passed: complete game, scoring, stop codon, restart, reference, persistence, storage fallbacks, API retries, keyboard, and mobile layout.');
    console.log('Screenshots: /tmp/protein-forge-{desktop,game,result,mobile}.png');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
