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
        roleTemp: number;
      };
    }
    // interface PageData {}
    // interface PageState {}
    // interface Platform {}
  }
}