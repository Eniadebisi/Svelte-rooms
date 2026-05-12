import { checkSignIn } from "$lib/server/user.model";
import type { PageServerLoad } from "./$types";
import type { Actions } from "./$types";
import { fail, redirect } from "@sveltejs/kit";
import { PUBLIC_SITE_NAME } from "$env/static/public";

export async function load({ locals }) {
  if (locals.user) redirect(302, "/reservations");

  return { PUBLIC_SITE_NAME };
}

export const actions: Actions = {
  signIn: async ({ cookies, request }) => {
    const data = Object.fromEntries(await request.formData());

    const {email, password} = data;

    if (!email || !password) {
      return fail(400, {
        error: "Missing email or password",
      });
    }

    // const { email, password } = formData as { email: string; password: string };

    const { error, token } = await checkSignIn(email, password);

    if (error) {
      return fail(401, {
        error,
      });
    }

    // Set the cookie
    cookies.set("AuthorizationToken", `Bearer ${token}`, {
      httpOnly: true,
      path: "/",
      secure: true,
      sameSite: "strict",
      maxAge: 60 * 60 * 24, // 1 day
    });

    throw redirect(302, "/reservations");
  },
  signOut: async (event) => {
	
    event.cookies.delete("AuthorizationToken", { path: "/" });

    throw redirect(302, "/");
  },
};
