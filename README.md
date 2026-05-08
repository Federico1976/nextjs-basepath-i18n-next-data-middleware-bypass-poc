# Next.js middleware matcher bypass on implicit default-locale `_next/data` routes with `basePath` + `i18n`

Minimal local reproduction for a Next.js Pages Router middleware matcher bypass involving:

- `basePath`
- `i18n`
- default locale
- Pages Router `getServerSideProps`
- framework-generated `_next/data/<BUILD_ID>/<page>.json` routes
- middleware matcher protection

The issue was responsibly reported to Vercel Open Source through HackerOne and closed as duplicate of a previously reported issue.

## Summary

A middleware matcher protects the SSR page:

```txt
/corp/base-admin
