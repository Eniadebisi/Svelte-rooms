import { hasPermission } from "$lib/permissions/auth.js";
import { error, redirect } from "@sveltejs/kit";

export async function load({ locals }) {
  if (!locals.user) throw error(400, { message: "Restricted" });
  const user = locals.user;

  if (!hasPermission(user, "UserManagement", "update")) throw error(400, { message: "Access restricted" });

  return { user };
}
