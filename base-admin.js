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
      BASE_ADMIN_PAGE{'\n'}
      SECRET={props.secret}{'\n'}
      COOKIE_SEEN={props.cookieSeen}{'\n'}
      LOCALE={props.locale}{'\n'}
      RESOLVED_URL={props.resolvedUrl}
    </pre>
  )
}
