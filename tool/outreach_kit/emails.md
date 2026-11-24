# Partner outreach: two email versions (A/B test)

Goal: find out whether local beach businesses want to be featured in Shore Thing, and
whether a $12/month price changes the answer. Same email to both groups, except group B
is told the price. Compare the "yes" rate between the groups.

Placeholders in {{double braces}} are filled in automatically by `mail_merge.gs`.

Rules we follow (keep it honest and legal):
- Don't claim users, downloads or partners we don't have. The app is pre-launch.
- Group A doesn't mention a price, but never say it's free. If someone asks about cost,
  answer honestly: "We're still deciding on pricing and wanted to hear from you first."
- Every email says who we are, gives a real reply address, and lets them opt out.
- US law (CAN-SPAM) asks commercial emails to include a postal address. Put a mailing
  address (a PO box works) in `SIGNATURE_ADDRESS` in `mail_merge.gs` before sending.
- Some countries (EU, UK, Australia, Brazil) have stricter rules about unsolicited emails,
  even to businesses. These addresses were published by the businesses themselves and the
  message is relevant to them, which is generally the accepted standard, but if you're
  unsure, start with the US beaches.

---

## Group A: interest, no price

**Subject:** Featuring {{business}} on Shore Thing's {{beach}} page?

Hi {{business}} team,

I'm Rishi, and I'm building Shore Thing, an app that helps people choose a beach by what
they want from the day: calm water, surf, food, lifeguards, and a live forecast.

Each beach in the app has its own page, and we're adding a "Local spots" section to the
{{beach}} page so visitors can find places like yours: your name, a photo, a line about
what you offer, and a link to your website or booking page.

Would you be interested in being featured there when we launch? A one-line reply is
perfect, and if you have a second, I'd love to know what would make it worthwhile for you.

Thanks for your time,
Rishi
Shore Thing · shorethingva26@gmail.com
{{address}}

If you'd rather not hear from us, just reply "no thanks" and we won't email again.

---

## Group B: interest, with the $12/month price

**Subject:** Featuring {{business}} on Shore Thing's {{beach}} page?

Hi {{business}} team,

I'm Rishi, and I'm building Shore Thing, an app that helps people choose a beach by what
they want from the day: calm water, surf, food, lifeguards, and a live forecast.

Each beach in the app has its own page, and we're adding a "Local spots" section to the
{{beach}} page so visitors can find places like yours: your name, a photo, a line about
what you offer, and a link to your website or booking page.

A featured spot would be $12 a month, and you could cancel any time.

Would you be interested when we launch? A one-line reply is perfect, and if you have a
second, I'd love to know what would make it worthwhile for you.

Thanks for your time,
Rishi
Shore Thing · shorethingva26@gmail.com
{{address}}

If you'd rather not hear from us, just reply "no thanks" and we won't email again.

---

## Tracking replies (this is your evidence for the pitch deck)

In the Google Sheet, fill in the `reply` column for each business: `yes`, `maybe`, `no`,
or leave blank for no answer. Then compare, per group:

- reply rate = replies ÷ emails sent
- interest rate = (yes + maybe) ÷ emails sent

If group B's interest is close to group A's, the $12 price isn't scaring people off.
If it's much lower, try a lower price (or a free first month) in a follow-up test.
