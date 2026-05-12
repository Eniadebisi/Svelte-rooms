// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
import type { Roles, Reservation, Room } from "@prisma/client";

declare global {
  namespace App {
    // interface Error {}
    interface Locals {
      user?: {
        name: string;
        id: number;
        email: string;
        role: Roles;
        generatedPW: boolean;
      };
    }
    // interface PageData {}
    // interface PageState {}
    // interface Platform {}
  }
  declare type EnhancedReservation = Reservation & {
    user: { name: string; role: Roles };
    Room: Pick<Room, "id" | "name" | "size" | "locationId" | "details">;
  };
}
