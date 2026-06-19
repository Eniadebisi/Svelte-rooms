import "dotenv/config";
import type { PrismaConfig } from "prisma/config";
import { defineConfig } from "prisma/config";

const { DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME } = process.env;

export default defineConfig({
  schema: "./prisma/schema.prisma",
  datasource: {
    url: `mysql://${DB_USER}:${encodeURIComponent(DB_PASSWORD ?? "")}@${DB_HOST}:${DB_PORT ?? 3306}/${DB_NAME}`,
  },
}) satisfies PrismaConfig;
