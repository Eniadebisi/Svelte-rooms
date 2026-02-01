declare module '$env/static/public' {
  export const PUBLIC_CONTACT_EMAIL: string;
  export const PUBLIC_SITE_NAME: string;
}

declare module '$env/static/private' {
  export const EMAIL_PASSWORD: string;
}

declare module '$env/dynamic/public' {
  const env: Record<string, string>;
  export = env;
}

declare module '$env/dynamic/private' {
  const env: Record<string, string>;
  export = env;
}
