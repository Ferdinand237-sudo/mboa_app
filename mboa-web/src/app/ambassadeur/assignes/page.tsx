import type { Metadata } from "next";
import { getCurrentUser } from "@/lib/data/auth";
import { getMesAssignations } from "@/lib/data/ambassadeur";
import { AssignationsList } from "@/components/ambassadeur/assignations-list";

export const metadata: Metadata = {
  title: "Propriétaires assignés",
};

// Miroir de AmbassadeurListeScreen (ambassadeur_liste_screen.dart).
export default async function AssignesPage() {
  const user = await getCurrentUser();
  const assignations = await getMesAssignations(user!.id);

  return (
    <div>
      <div className="bg-white px-5 py-4">
        <h1 className="mx-auto max-w-3xl text-lg font-extrabold text-mboa-text">📋 Propriétaires assignés</h1>
      </div>
      <AssignationsList assignations={assignations} userId={user!.id} />
    </div>
  );
}
