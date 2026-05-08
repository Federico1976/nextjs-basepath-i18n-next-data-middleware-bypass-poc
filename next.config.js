/** @type {import('next').NextConfig} */
module.exports = {
  basePath: '/corp',
  trailingSlash: false,
  i18n: {
    locales: ['en', 'it', 'fr'],
    defaultLocale: 'en',
    localeDetection: false,
  },
}
