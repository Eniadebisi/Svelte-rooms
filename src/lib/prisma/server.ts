import { PrismaClient } from "@prisma/client";

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma =
  global.prisma ||
  new PrismaClient({
    // * Uncomment this to see the SQL queries in the console
    // log: MODE === 'development' ? ['query', 'error', 'warn'] : ['error']
  });

if (process.env.MODE !== "PRODUCTION") {
  global.prisma = prisma;
}
