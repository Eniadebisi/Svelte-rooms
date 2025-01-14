import { resetPW, setUserRole } from "$lib/server/user.model.js";
import { json } from "@sveltejs/kit";
import nodemailer from "nodemailer";
import { EMAIL_PASSWORD } from "$env/static/private";
import dayjs from "dayjs";
import { CONTACT_EMAIL, SITE_NAME } from "$lib/settings.js";

const transporter = nodemailer.createTransport({
  host: "smtp.titan.email",
  port: 465,
  secure: true,
  auth: {
    user: CONTACT_EMAIL,
    pass: EMAIL_PASSWORD,
  },
});

export async function POST({ request }) {
  const { userId, newrole, selFunction, email, userName } = await request.json();

  switch (selFunction) {
    case "editRole":
      if (userId && newrole) {
        let { error } = await setUserRole(userId, newrole);

        if (error) {
          return json({ error }, { status: 400 });
        }
        return json({ error: false }, { status: 201 });
      }
      break;
    case "resetPW":
      if (userId && selFunction && email) {
        return json({ error: "Not setup" }, { status: 400 });
        const newTempPassword = Math.random().toString(36).slice(2);
        const deadline = new Date();
        deadline.setDate(deadline.getDate() + 7);
        const { error } = await resetPW(userId, newTempPassword, deadline);
        if (error) {
          return json({ error: error }, { status: 400 });
        }
        const info = await transporter.sendMail({
          from: "Support <" + CONTACT_EMAIL + ">",
          to: "eniadebisi@gmail.com",
          subject: "Room reservation password reset",
          html: "<div style='text-align: center;'> <h1> " + SITE_NAME + "Reset</h1> <p>Hello, " + userName + "This will be your new temporary password: '" + newTempPassword + "'</p>  <p>You will have until " + dayjs(deadline).format() + " to reset your password from now.</p></div>",
        });
        console.log("Message sent " + info.messageId);
      }

      return json({ error: false }, { status: 201 });

    default:
      break;
  }

  return json({ error: "Error updating roleTemp" }, { status: 400 });
}
