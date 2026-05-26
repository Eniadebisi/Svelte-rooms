import "dotenv/config";
import type { PrismaConfig } from "prisma/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "./prisma/schema.prisma",
  datasource: {
    url: env("DATABASE_URL"), 
  },
}) satisfies PrismaConfig;