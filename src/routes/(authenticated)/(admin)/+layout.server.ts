import { hasPermission } from "$lib/permissions/auth.js";
import { error, redirect } from "@sveltejs/kit";

export async function load({ locals }) {
  const user = locals.user;

  if (!user) throw error(400, { message: "Restricted" });
  if (user.roleTemp < 2) throw error(400, { message: "Access restricted" });

  return { user };
}
