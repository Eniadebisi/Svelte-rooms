import "dotenv/config";
import { PrismaClient } from "../../../prisma/generated/client";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

const adapter = new PrismaMariaDb({
  database: process.env.DB_NAME,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : undefined,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectionLimit: 5,
  allowPublicKeyRetrieval: true,
});

export const prisma = global.prisma || new PrismaClient({
  adapter,
  log: ["info", "warn", "error"],
});

// db.$on("query", (e) => {})

export async function queryRooms() {
  const rooms = await prisma.room.findMany();
  return rooms;
}
