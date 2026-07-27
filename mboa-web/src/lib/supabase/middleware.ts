import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Rafraîchit la session Supabase à chaque requête et propage les cookies mis
// à jour vers le navigateur.
//
// Ne redirige plus systématiquement un admin/ambassadeur vers /admin ou
// /ambassadeur : depuis que ces rôles sont des privilèges superposables
// (estAdmin/estAmbassadeur) plutôt qu'un rôle exclusif, un compte promu
// garde l'expérience de son compte initial par défaut et entre dans son
// espace dédié via le lien "Administration"/"Espace ambassadeur" du profil
// (voir profil/page.tsx et header-client.tsx pour la navigation devenue
// sensible au chemin courant).
export async function updateSession(request: NextRequest) {
  // Filet de sécurité OAuth : si le ?code=... PKCE atterrit ailleurs que sur
  // /auth/callback (ex. Supabase retombe sur le Site URL du dashboard faute
  // d'un motif générique dans Redirect URLs, comme *.vercel.app/**), on le
  // redirige nous-mêmes vers la route qui sait l'échanger, plutôt que de
  // dépendre uniquement d'un réglage dashboard correctement renseigné.
  const code = request.nextUrl.searchParams.get("code");
  if (code && request.nextUrl.pathname !== "/auth/callback") {
    const callbackUrl = new URL("/auth/callback", request.url);
    callbackUrl.searchParams.set("code", code);
    callbackUrl.searchParams.set("next", request.nextUrl.pathname);
    return NextResponse.redirect(callbackUrl);
  }

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

  // Garde la session à jour côté cookies ; ne fait plus de lecture ni de
  // redirection basée sur le rôle ici (voir commentaire de fonction).
  await supabase.auth.getUser();

  return supabaseResponse;
}
