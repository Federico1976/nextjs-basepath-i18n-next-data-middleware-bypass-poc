import { NextResponse } from 'next/server'

export function middleware(req) {
  return new NextResponse(
    'SIMPLE_MATCHER_HIT path=' +
      req.nextUrl.pathname +
      ' url=' +
      req.url +
      ' locale=' +
      req.nextUrl.locale +
      ' basePath=' +
      req.nextUrl.basePath,
    { status: 451 }
  )
}

export const config = {
  matcher: [
    '/base-admin/:path*',
  ],
}
