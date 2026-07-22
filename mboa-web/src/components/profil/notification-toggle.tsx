"use client";

import { useState, useSyncExternalStore } from "react";
import { Switch } from "@/components/ui/switch";

const KEY = "mboa_notifications_activees";

function subscribe(callback: () => void) {
  window.addEventListener("storage", callback);
  return () => window.removeEventListener("storage", callback);
}
function getSnapshot() {
  const v = window.localStorage.getItem(KEY);
  return v === null ? true : v === "true";
}
function getServerSnapshot() {
  return true;
}

// Miroir de _basculerNotifications (profil_screen.dart) : SharedPreferences
// devient localStorage côté web.
export function NotificationToggle() {
  const stored = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  const [override, setOverride] = useState<boolean | null>(null);
  const value = override ?? stored;

  function toggle(next: boolean) {
    window.localStorage.setItem(KEY, String(next));
    setOverride(next);
  }

  return <Switch checked={value} onChange={toggle} />;
}
