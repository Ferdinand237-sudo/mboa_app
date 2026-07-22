import type { Metadata } from "next";
import { getTousContributeurs } from "@/lib/data/contributeurs";
import { PageHeader } from "@/components/ui/page-header";
import { ContributeursClient } from "@/components/home/contributeurs-client";

export const metadata: Metadata = {
  title: "Contributeurs",
};

// Miroir de contributeurs_screen.dart.
export default async function ContributeursPage() {
  const contributeurs = await getTousContributeurs();

  return (
    <div>
      <PageHeader title="🤝 Contributeurs" />
      <ContributeursClient contributeurs={contributeurs} />
    </div>
  );
}
