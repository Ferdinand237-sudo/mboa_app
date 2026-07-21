import { getCurrentUser } from "@/lib/data/auth";
import { HeaderClient } from "./header-client";

export async function Header() {
  const user = await getCurrentUser();
  return <HeaderClient user={user} />;
}
