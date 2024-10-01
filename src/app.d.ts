// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
import type { Reservation } from "@prisma/client";

declare global {
  namespace App {
    // interface Error {}
    interface Locals {
      user?: {
        name: string;
        id: number;
        email: string;
        role: number;
      };
    }
    // interface PageData {}
    // interface PageState {}
    // interface Platform {}
  }
}

interface Reservation extends Reservation {
  user: {
    name: string;
    role: string;
  };
}
