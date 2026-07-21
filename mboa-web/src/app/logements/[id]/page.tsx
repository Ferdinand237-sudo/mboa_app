import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getLogement } from "@/lib/data/logements";
import { getCurrentUser } from "@/lib/data/auth";
import { formatPrix, formatDateFr } from "@/lib/utils/format";
import { EQUIPEMENTS } from "@/lib/constants";
import { Gallery } from "@/components/ui/gallery";
import { Badge } from "@/components/ui/badge";
import { ContactCard } from "@/components/ui/contact-card";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const logement = await getLogement(id);
  if (!logement) return { title: "Logement introuvable" };
  return {
    title: `${logement.titre} — ${formatPrix(logement.prix)}`,
    description: logement.description.slice(0, 160),
  };
}

export default async function LogementDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [logement, user] = await Promise.all([
    getLogement(id),
    getCurrentUser(),
  ]);

  if (!logement) notFound();

  const equipementIcons = new Map(EQUIPEMENTS.map((e) => [e.label, e.icon]));

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <div className="grid gap-8 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Gallery photos={logement.photos} alt={logement.titre} />

          <div className="mt-6 flex flex-wrap items-center gap-2">
            <Badge variant="neutral">{logement.type}</Badge>
            {logement.boosted && <Badge variant="boost">✦ Boosté</Badge>}
            {logement.proprietaireVerified && (
              <Badge variant="verified">✓ Propriétaire vérifié</Badge>
            )}
          </div>

          <h1 className="mt-3 text-2xl font-extrabold text-mboa-text sm:text-3xl">
            {logement.titre}
          </h1>
          <p className="mt-1 text-sm text-mboa-text-muted">
            📍 {logement.adresseApprox ?? logement.quartier ?? logement.ville},{" "}
            {logement.ville}
          </p>
          <p className="mt-3 text-2xl font-extrabold text-mboa-primary">
            {formatPrix(logement.prix)}
            <span className="text-sm font-medium text-mboa-text-muted"> / mois</span>
          </p>

          <div className="mt-8">
            <h2 className="text-lg font-bold text-mboa-text">Description</h2>
            <p className="mt-2 whitespace-pre-line text-sm leading-relaxed text-mboa-text-muted">
              {logement.description}
            </p>
          </div>

          {logement.equipements.length > 0 && (
            <div className="mt-8">
              <h2 className="text-lg font-bold text-mboa-text">Équipements</h2>
              <div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3">
                {logement.equipements.map((eq) => (
                  <div
                    key={eq}
                    className="flex items-center gap-2 rounded-mboa-md border border-mboa-border bg-mboa-card px-3 py-2 text-sm text-mboa-text"
                  >
                    <span aria-hidden>{equipementIcons.get(eq) ?? "•"}</span>
                    {eq}
                  </div>
                ))}
              </div>
            </div>
          )}

          {logement.regles.length > 0 && (
            <div className="mt-8">
              <h2 className="text-lg font-bold text-mboa-text">Règles</h2>
              <ul className="mt-3 space-y-1.5 text-sm text-mboa-text-muted">
                {logement.regles.map((regle) => (
                  <li key={regle}>• {regle}</li>
                ))}
              </ul>
            </div>
          )}

          <div className="mt-8 grid grid-cols-2 gap-4 text-sm text-mboa-text-muted sm:grid-cols-3">
            {logement.surface && <div>📐 {logement.surface} m²</div>}
            <div>👁 {logement.vues} vues</div>
            <div>📅 Publié le {formatDateFr(logement.datePublication)}</div>
          </div>
        </div>

        <aside className="lg:sticky lg:top-24 lg:h-fit">
          <ContactCard
            nom={logement.proprietaireNom ?? "Propriétaire"}
            verified={logement.proprietaireVerified}
            note={logement.noteGlobale}
            nbAvis={logement.nbAvis}
            isLoggedIn={!!user}
          />
        </aside>
      </div>
    </div>
  );
}
