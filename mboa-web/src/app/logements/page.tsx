import type { Metadata } from "next";
import { getLogements } from "@/lib/data/logements";
import { getCurrentUser } from "@/lib/data/auth";
import { LogementCard } from "@/components/logement/logement-card";
import { VisitorGate } from "@/components/ui/visitor-gate";
import { TYPES_LOGEMENT, PAGE_SIZE, PAGE_SIZE_VISITEUR } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Logements à Sangmelima",
  description:
    "Chambres, studios et appartements disponibles à Sangmelima pour les étudiants.",
};

const PRIX_OPTIONS = [
  { label: "Tous les prix", value: "" },
  { label: "Jusqu'à 20 000 FCFA", value: "20000" },
  { label: "Jusqu'à 40 000 FCFA", value: "40000" },
  { label: "Jusqu'à 60 000 FCFA", value: "60000" },
  { label: "Jusqu'à 100 000 FCFA", value: "100000" },
];

export default async function LogementsPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const params = await searchParams;
  const search = typeof params.search === "string" ? params.search : undefined;
  const type = typeof params.type === "string" ? params.type : undefined;
  const prixMaxParam = typeof params.prixMax === "string" ? params.prixMax : undefined;
  const prixMax = prixMaxParam ? Number(prixMaxParam) : undefined;

  const user = await getCurrentUser();
  const limit = user ? PAGE_SIZE : PAGE_SIZE_VISITEUR;

  const logements = await getLogements({ type, prixMax, search, limit });

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
      <h1 className="text-2xl font-extrabold text-mboa-text sm:text-3xl">
        Logements à Sangmelima
      </h1>
      <p className="mt-1 text-sm text-mboa-text-muted">
        Chambres, studios et appartements proposés par des propriétaires
        vérifiés.
      </p>

      <form className="mt-6 flex flex-wrap gap-3 rounded-mboa-lg border border-mboa-border bg-mboa-card p-4">
        <input
          type="text"
          name="search"
          defaultValue={search}
          placeholder="Titre, quartier, description..."
          className="min-w-[200px] flex-1 rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        />
        <select
          name="type"
          defaultValue={type ?? ""}
          className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        >
          <option value="">Tous les types</option>
          {TYPES_LOGEMENT.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
        <select
          name="prixMax"
          defaultValue={prixMaxParam ?? ""}
          className="rounded-mboa-md border border-mboa-border bg-mboa-background px-4 py-2.5 text-sm outline-none focus:border-mboa-primary"
        >
          {PRIX_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        <button
          type="submit"
          className="rounded-mboa-md bg-mboa-primary px-6 py-2.5 text-sm font-bold text-white"
        >
          Filtrer
        </button>
      </form>

      {logements.length === 0 ? (
        <div className="mt-10 rounded-mboa-lg border border-mboa-border bg-mboa-card p-10 text-center text-sm text-mboa-text-muted">
          Aucun logement ne correspond à ta recherche pour le moment.
        </div>
      ) : (
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {logements.map((logement) => (
            <LogementCard key={logement.id} logement={logement} />
          ))}
          {!user && logements.length >= PAGE_SIZE_VISITEUR && <VisitorGate />}
        </div>
      )}
    </div>
  );
}
