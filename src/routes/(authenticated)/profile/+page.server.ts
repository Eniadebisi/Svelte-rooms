import { checkSignIn, updatePassword } from "$lib/server/user.model.js";
import type { PageServerLoad, Actions } from "./$types";
import { fail, redirect } from "@sveltejs/kit";

export const load: PageServerLoad = async ({ locals }) => {
  return { user: locals.user };
};

export const actions: Actions = {
  updatePW: async ({ cookies, request, locals }) => {
    const data = Object.fromEntries(await request.formData());
    const user = locals.user;

    if (!user) {
      return fail(401, { error: "Not authenticated." });
    }

    const currPW = data.currPW as string;
    const newPW = data.newPW as string;
    const CnfnewPW = data.CnfnewPW as string;

    if (!currPW || !newPW || !CnfnewPW) {
      return fail(400, { error: "All password fields are required." });
    }

    if (newPW !== CnfnewPW) {
      return fail(400, { error: "New passwords don't match." });
    }

    const { error } = await checkSignIn(user.email, currPW);

    if (error) {
      return fail(401, { error: "Current password is incorrect." });
    }

    const { error: updateError } = await updatePassword(user.id, newPW);

    if (updateError) {
      return fail(500, { error: updateError });
    }

    cookies.delete("AuthorizationToken", { path: "/" });
    throw redirect(302, "/");
  },
};
