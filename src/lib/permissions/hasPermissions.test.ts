// // hasPermission.test.ts
// import type { User, Roles, Reservation, Room, Location } from "@prisma/client";
// import { hasPermission, ROLES } from "./auth"; // Replace with your actual path
// import { expect, test } from "vitest";

// test("hasPermission works for all users", () => {
//   const OwnerUser: User = { name: "OwnerUser", id: 1, email: "test@gmail.com", password: "", role: "Owner" };
//   expect(hasPermission(OwnerUser, "Reservation", "create")).toBe(true);
//   expect(hasPermission(OwnerUser, "Reservation", "view")).toBe(true);
//   expect(hasPermission(OwnerUser, "Reservation", "update")).toBe(true);
//   expect(hasPermission(OwnerUser, "Reservation", "delete")).toBe(true);
//   expect(hasPermission(OwnerUser, "Location", "create")).toBe(true);
//   expect(hasPermission(OwnerUser, "Location", "view")).toBe(true);
//   expect(hasPermission(OwnerUser, "Location", "update")).toBe(true);
//   expect(hasPermission(OwnerUser, "Location", "delete")).toBe(true);
//   expect(hasPermission(OwnerUser, "Room", "create")).toBe(true);
//   expect(hasPermission(OwnerUser, "Room", "view")).toBe(true);
//   expect(hasPermission(OwnerUser, "Room", "update")).toBe(true);
//   expect(hasPermission(OwnerUser, "Room", "delete")).toBe(true);
  
//   const AdminUser: User = { name: "AdminUser", id: 1, email: "test@gmail.com", password: "", role: 3, role: "Admin" };
//   expect(hasPermission(AdminUser, "Reservation", "create")).toBe(true);
//   expect(hasPermission(AdminUser, "Reservation", "view")).toBe(true);
//   expect(hasPermission(AdminUser, "Reservation", "update")).toBe(true);
//   expect(hasPermission(AdminUser, "Reservation", "delete")).toBe(true);
//   expect(hasPermission(AdminUser, "Room", "create")).toBe(true);
//   expect(hasPermission(AdminUser, "Room", "view")).toBe(true);
//   expect(hasPermission(AdminUser, "Room", "update")).toBe(true);
//   expect(hasPermission(AdminUser, "Room", "delete")).toBe(true);
//   expect(hasPermission(AdminUser, "Location", "create")).toBe(false);
//   expect(hasPermission(AdminUser, "Location", "view")).toBe(true);
//   expect(hasPermission(AdminUser, "Location", "update")).toBe(true);
//   expect(hasPermission(AdminUser, "Location", "delete")).toBe(true);
  
//   const RegularUserNotOwnReservation: User = { name: "RegularUserNotOwnReservation", id: 1, email: "test@gmail.com", password: "", role: "User" };
//   const reservation: Reservation = {id: 1,
//     roomId: 1,
//     userId: 2,
//     startTime: new Date("2024-12-11T22:08:27.192Z"),
//     details: "n/a",
//     length: 3,
//     title: "Reservation",
//     endTime: null
//   }
//   expect(hasPermission(RegularUserNotOwnReservation, "Reservation", "create", reservation)).toBe(true);
//   expect(hasPermission(RegularUserNotOwnReservation, "Reservation", "view")).toBe(true);
//   expect(hasPermission(RegularUserNotOwnReservation, "Reservation", "update", reservation)).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Reservation", "delete", reservation)).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Room", "create")).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Room", "view")).toBe(true);
//   expect(hasPermission(RegularUserNotOwnReservation, "Room", "update")).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Room", "delete")).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Location", "create")).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Location", "view")).toBe(true);
//   expect(hasPermission(RegularUserNotOwnReservation, "Location", "update")).toBe(false);
//   expect(hasPermission(RegularUserNotOwnReservation, "Location", "delete")).toBe(false);
  

//   const RegularUserOwnReservation: User = { name: "RegularUserOwnReservation", id: 2, email: "test@gmail.com", password: "", role: 3, role: "User" };
  
//   expect(hasPermission(RegularUserOwnReservation, "Reservation", "create", reservation)).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Reservation", "view")).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Reservation", "update", reservation), RegularUserOwnReservation.id + " <= this should equal this => " + reservation.userId).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Reservation", "delete", reservation)).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Room", "create")).toBe(false);
//   expect(hasPermission(RegularUserOwnReservation, "Room", "view")).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Room", "update")).toBe(false);
//   expect(hasPermission(RegularUserOwnReservation, "Room", "delete")).toBe(false);
//   expect(hasPermission(RegularUserOwnReservation, "Location", "create")).toBe(false);
//   expect(hasPermission(RegularUserOwnReservation, "Location", "view")).toBe(true);
//   expect(hasPermission(RegularUserOwnReservation, "Location", "update")).toBe(false);
//   expect(hasPermission(RegularUserOwnReservation, "Location", "delete")).toBe(false);

//   //   it('should allow User to update their own reservation', () => {
//   //     const user: User = { id: 'user1', role: 'User' };
//   //     const resource = 'Reservation' as 'Reservation';
//   //     const action = 'update';
//   //     const data: Reservation = { userId: 'user1' };

//   //     expect(hasPermission(user, resource, action, data)).toBe(true);
//   //   });

//   //   it('should deny User to update another user\'s reservation', () => {
//   //     const user: User = { id: 'user1', role: 'User' };
//   //     const resource = 'Reservation' as 'Reservation';
//   //     const action = 'update';
//   //     const data: Reservation = { userId: 'user2' };

//   //     expect(hasPermission(user, resource, action, data)).toBe(false);
//   //   });

//   //   it('should deny Guest to view a Room', () => {
//   //     const user: User = { id: 'user1', role: 'Guest' };
//   //     const resource = 'Room' as 'Room';
//   //     const action = 'view';

//   //     expect(hasPermission(user, resource, action)).toBe(false);
//   //   });

//   //   it('should return false for non-existent resource', () => {
//   //     const user: User = { id: 'user1', role: 'Owner' };
//   //     const resource = 'NonExistentResource' as any; // Invalid resource
//   //     const action = 'create';

//   //     expect(hasPermission(user, resource, action)).toBe(false);
//   //   });
// });
