import { getUsers } from "$lib/server/user.model";
import { redirect } from "@sveltejs/kit";
import type { PageServerLoad } from "./$types";

export async function load({ parent }) {
  let { user } = await parent();
  if (user && user.roleTemp < 2) redirect(302, "/reservations");

  return { users: await getUsers(), user };
}
