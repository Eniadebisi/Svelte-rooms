// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
import type { Roles } from "@prisma/client";

declare global {
  namespace App {
    // interface Error {}
    interface Locals {
      user?: {
        name: string;
        id: number;
        email: string;
        role: Roles;
      };
    }
    // interface PageData {}
    // interface PageState {}
    // interface Platform {}
  }
}