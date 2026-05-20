import { error, redirect } from "@sveltejs/kit";

export async function load({ locals, url }) {
  const user = locals.user;

  if (!user) throw error(400, { message: "Restricted" });

  if (user.generatedPW && !url.pathname.startsWith("/profile")) {
    throw redirect(302, "/profile");
  }

  return { user };
}
