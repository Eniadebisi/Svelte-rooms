// import { checkSignIn } from "$lib/server/user.model";
// import type { PageServerLoad } from "./$types";
// import type { Actions } from "./$types";
// import { error, fail, redirect } from "@sveltejs/kit";

// export async function load({}) {
//   return {};
// }

// export const actions: Actions = {
//   updatePW: async ({ cookies, request, locals }) => {
//     const data = Object.fromEntries(await request.formData());
//     const user = locals.user;

//     if (!user) {
//       return fail(401, { error: "User object not received." });
//     }

//     const email = user.email;
//     const password = data.password;
//     const newPW = data.newPW;
//     const CnfnewPW = data.CnfnewPW;

//     if (!password || !newPW || !CnfnewPW) {
//       return fail(401, { error: "Password is blank." });
//     }

//     if (newPW != CnfnewPW) {
//       return fail(401, { error: "New passwords don't match." });
//     }

//     const { error, token: __ } = await checkSignIn(email, password);

//     if (error) {
//       return fail(401, {
//         error,
//       });
//     }
//     cookies.delete("AuthorizationToken", { path: "/" });

//     throw redirect(302, "/");
//   },
// };
