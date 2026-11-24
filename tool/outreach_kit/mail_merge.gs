/**
 * Shore Thing partner outreach: Gmail mail merge for Google Sheets.
 *
 * Setup (once):
 *   1. Open sheets.new, then File → Import → Upload → tool/outreach/businesses.csv
 *      → "Replace current sheet".
 *   2. Extensions → Apps Script. Delete what's there, paste this whole file, Save.
 *   3. Change SIGNATURE_ADDRESS below to your mailing address (a PO box is fine).
 *   4. Run "testToMyself" first: it sends you one A and one B email to check.
 *      (Google asks for permission the first time: allow it.)
 *   5. Run "sendBatch". It sends up to DAILY_MAX emails, alternating group A and B so both
 *      groups go out on the same days, and writes the time in the "sent" column.
 *      Run it again tomorrow (or Triggers → Add trigger → sendBatch, daily) until done.
 *
 * Free Gmail accounts can send to about 100 people a day from a script; 50 a day is
 * gentler and less likely to land in spam.
 */

const DAILY_MAX = 50;
const FROM_NAME = 'Rishi at Shore Thing';
const SIGNATURE_ADDRESS = 'YOUR MAILING ADDRESS HERE';

const SUBJECT = 'Featuring {{business}} on Shore Thing\'s {{beach}} page?';

const INTRO =
  'Hi {{business}} team,\n\n' +
  'I\'m Rishi, and I\'m building Shore Thing, an app that helps people choose a beach by what ' +
  'they want from the day: calm water, surf, food, lifeguards, and a live forecast.\n\n' +
  'Each beach in the app has its own page, and we\'re adding a "Local spots" section to the ' +
  '{{beach}} page so visitors can find places like yours: your name, a photo, a line about ' +
  'what you offer, and a link to your website or booking page.\n\n';

const ASK_A =
  'Would you be interested in being featured there when we launch? A one-line reply is ' +
  'perfect, and if you have a second, I\'d love to know what would make it worthwhile for you.\n\n';

const ASK_B =
  'A featured spot would be $12 a month, and you could cancel any time.\n\n' +
  'Would you be interested when we launch? A one-line reply is perfect, and if you have a ' +
  'second, I\'d love to know what would make it worthwhile for you.\n\n';

const SIGN_OFF =
  'Thanks for your time,\nRishi\nShore Thing · shorethingva26@gmail.com\n{{address}}\n\n' +
  'If you\'d rather not hear from us, just reply "no thanks" and we won\'t email again.';

function fill_(text, row) {
  return text
    .replace(/{{business}}/g, row.business)
    .replace(/{{beach}}/g, row.beach)
    .replace(/{{address}}/g, SIGNATURE_ADDRESS);
}

function bodyFor_(row) {
  return fill_(INTRO + (row.group === 'B' ? ASK_B : ASK_A) + SIGN_OFF, row);
}

function readSheet_() {
  const sheet = SpreadsheetApp.getActiveSheet();
  const values = sheet.getDataRange().getValues();
  const header = values[0].map(String);
  for (const col of ['sent', 'reply']) {
    if (!header.includes(col)) {
      header.push(col);
      sheet.getRange(1, header.length).setValue(col);
    }
  }
  const idx = Object.fromEntries(header.map((h, i) => [h, i]));
  const rows = values.slice(1).map((v, i) => ({
    line: i + 2,
    group: String(v[idx.group]),
    beach: String(v[idx.beach]),
    business: String(v[idx.business]),
    email: String(v[idx.email]).trim(),
    sent: v[idx.sent] || '',
  }));
  return { sheet, idx, rows };
}

/** Sends one example of each email to you, so you can check them first. */
function testToMyself() {
  const me = Session.getActiveUser().getEmail();
  const { rows } = readSheet_();
  for (const g of ['A', 'B']) {
    const row = rows.find(r => r.group === g);
    if (!row) continue;
    GmailApp.sendEmail(me, '[TEST ' + g + '] ' + fill_(SUBJECT, row), bodyFor_(row), { name: FROM_NAME });
  }
}

/** Sends the next batch, alternating A and B, and records the time sent. */
function sendBatch() {
  if (SIGNATURE_ADDRESS.indexOf('YOUR') === 0) {
    throw new Error('Set SIGNATURE_ADDRESS at the top of the script first.');
  }
  const { sheet, idx, rows } = readSheet_();
  const queue = {
    A: rows.filter(r => r.group === 'A' && !r.sent && r.email),
    B: rows.filter(r => r.group === 'B' && !r.sent && r.email),
  };
  const limit = Math.min(DAILY_MAX, MailApp.getRemainingDailyQuota());
  let sent = 0;
  while (sent < limit && (queue.A.length || queue.B.length)) {
    const g = (sent % 2 === 0 && queue.A.length) || !queue.B.length ? 'A' : 'B';
    const row = queue[g].shift();
    GmailApp.sendEmail(row.email, fill_(SUBJECT, row), bodyFor_(row), {
      name: FROM_NAME,
      replyTo: 'shorethingva26@gmail.com',
    });
    sheet.getRange(row.line, idx.sent + 1).setValue(new Date());
    sent++;
    Utilities.sleep(1500);
  }
  Logger.log('Sent ' + sent + '. Left: A ' + queue.A.length + ', B ' + queue.B.length + '.');
}
