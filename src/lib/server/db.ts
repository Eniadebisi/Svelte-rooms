import { PrismaClient } from "../../../prisma/generated/client";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

const adapter = new PrismaMariaDb({
  database: process.env.DB_NAME,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectionLimit: 5,
  connectTimeout: 10000,
});

export const prisma = global.prisma ?? new PrismaClient({
  adapter,
  log: ["info", "warn", "error"],
});

export async function queryRooms() {
  const rooms = await prisma.room.findMany();
  return rooms;
}
