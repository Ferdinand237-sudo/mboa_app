import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Rafraîchit la session Supabase à chaque requête, propage les cookies mis à
// jour vers le navigateur, et redirige un admin connecté vers /admin.
//
// Miroir de MainScreen.initState côté mobile (role === 'admin' ->
// context.go(AppRoutes.admin)) : sur le web il n'y a pas d'IndexedStack
// unique à rediriger en interne au login, donc c'est fait ici, en amont de
// CHAQUE requête — pas seulement juste après la connexion — pour couvrir
// aussi un onglet déjà ouvert, un lien direct, ou un simple clic sur le
// logo qui ramènerait sinon un admin vers les pages étudiant/visiteur.
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user && !request.nextUrl.pathname.startsWith("/admin")) {
    const { data } = await supabase.from("users").select("role").eq("id", user.id).single();
    if (data?.role === "admin") {
      return NextResponse.redirect(new URL("/admin", request.url));
    }
  }

  return supabaseResponse;
}
