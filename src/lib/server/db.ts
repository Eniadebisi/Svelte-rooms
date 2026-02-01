import "dotenv/config";
import { PrismaClient } from "../../../prisma/generated/client";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";

const adapter = new PrismaMariaDb({
  database: process.env.DB_NAME,
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || "3306"),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectionLimit: 5,
});

export const prisma = new PrismaClient({
  adapter,
  log: ["info", "warn", "error"],
});

// db.$on("query", (e) => {})

export async function queryRooms() {
  const rooms = await prisma.room.findMany();
  return rooms;
}
