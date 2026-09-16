# Cabinet Hardware Website — Setup Guide

This is a complete, standalone website (not connected to Oneaccounts). It has:
- A public storefront: homepage, catalog, product pages with variants (finish/size), cart, checkout by bank transfer, and order tracking.
- A password-protected admin area at `/admin` to manage products, variants, stock, and orders.

You do not need to write any code to run this — just follow the steps below in order.

---

## Part 1 — Set up the database (Supabase)

1. **Create a free account** at [supabase.com](https://supabase.com) if you don't have one, and create a new project. Save the database password it gives you somewhere safe.
2. Once the project is ready, click **SQL Editor** in the left sidebar, then **New query**.
3. Open `schema.sql` (in this folder) in any text editor, copy everything, paste it into the SQL Editor, and click **Run**. This creates all the tables.
4. *(Optional but recommended for your first look)* Repeat step 3 with `sample-data.sql` to add a few example products, so the site isn't empty. You can delete these later from the admin panel.
5. Go to **Project Settings → API**. You'll need three values from this page in Part 2:
   - **Project URL**
   - **anon public** key
   - **service_role** key (keep this one secret — never share it or put it in the browser-facing code)

---

## Part 2 — Connect the website to your database

1. In this project folder, make a copy of the file `.env.example` and rename the copy to `.env.local`.
2. Open `.env.local` and paste in the three values from Supabase Part 1, step 5.
3. Save the file.

---

## Part 3 — Create your admin login

1. In Supabase, go to **Authentication → Users**, click **Add user**, and create yourself an account with your email and a password. This is what you'll use to log into `/admin` on the website.

---

## Part 4 — Run it on your computer to check it works

*(You'll need [Node.js](https://nodejs.org) installed — download the "LTS" version if you don't have it.)*

1. Open a terminal/command prompt in this project folder.
2. Run:
   ```
   npm install
   ```
   (This downloads everything the site needs — only takes a minute.)
3. Run:
   ```
   npm run dev
   ```
4. Open your browser to **http://localhost:3000** — you should see the homepage.
5. Go to **http://localhost:3000/admin** and log in with the account you made in Part 3.

If the homepage loads and shows the sample product, everything is wired up correctly.

---

## Part 5 — Put it online (deploy)

1. Create a free account at [github.com](https://github.com) if you don't have one, and create a new repository.
2. Upload this whole project folder to that repository (GitHub's website lets you drag-and-drop files if you'd rather not use the command line).
3. Create a free account at [vercel.com](https://vercel.com), click **Add New → Project**, and import the GitHub repository you just created.
4. When Vercel asks for environment variables, enter the same three values from your `.env.local` file (Part 2).
5. Click **Deploy**. In a couple of minutes you'll get a live web address for your store.
6. Later, you can attach your own domain name (like `yourstore.com`) under the project's **Settings → Domains** in Vercel.

---

## Using the admin panel day-to-day

- **Add a product**: `/admin/products/new` — fill in the name, description, specs (like material), and one row per variant (finish + size + price + stock). Leave "Size" blank on a row if that product doesn't come in different sizes.
- **Manage stock**: stock is set per variant when you add or edit a product.
- **Orders**: `/admin/orders` shows every order. Once you've checked your bank statement and received a payment, click **Mark as paid**. Update the delivery status (packed/shipped/delivered) as the order moves along — the customer sees this live on their tracking page.
- **Bank details shown to customers**: update the `bank_settings` table directly in Supabase's Table Editor (Authentication isn't required for this one — it's just data). I can build a proper settings screen for this in the admin panel next if you'd like.

---

## What's not included yet (possible next steps)

- A settings screen for editing bank details from the admin panel (currently edited directly in Supabase)
- Image upload from your computer (currently: paste an image URL — you can upload photos to Supabase's Storage section and paste the link it gives you)
- Card payments (Razorpay/Stripe) — bank transfer only for now, as requested
- Email notifications to customers when their order status changes
- Linking this back to Oneaccounts, when/if you're ready for that - it is test
