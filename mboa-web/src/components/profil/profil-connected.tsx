"use client";

import { useState } from "react";
import Link from "next/link";
import type { UserModel } from "@/lib/types/models";
import type { ProfilStats } from "@/lib/data/profil-stats";
import { initiales, formatDateFr } from "@/lib/utils/format";
import { MenuSection, MenuItem } from "@/components/profil/menu-item";
import { NotificationToggle } from "@/components/profil/notification-toggle";
import { LogoutButton } from "@/components/profil/logout-button";
import { ChangePasswordDialog } from "@/components/profil/change-password-dialog";
import { InfoDialog } from "@/components/profil/info-dialog";
import { AboutDialog } from "@/components/profil/about-dialog";
import {
  HeartIcon,
  BellIcon,
  ChatIcon,
  StarIcon,
  PersonIcon,
  PhoneIcon,
  LockIcon,
  StorefrontIcon,
  AddBusinessIcon,
  ShieldIcon,
  HelpIcon,
  InfoIcon,
  EditIcon,
} from "@/components/ui/icons";

const ROLE_LABELS: Record<string, string> = {
  vendeur: "🏪 Vendeur / Commerçant",
  admin: "👑 Administrateur",
  ambassadeur: "🧭 Ambassadeur Mboa",
  visiteur: "🎓 Étudiant / Visiteur",
};

// Miroir exact de _buildConnected (profil_screen.dart) : header dégradé avec
// avatar/badges/stats, sections "Mes activités", "Mon compte", "Paramètres",
// badge de rôle, déconnexion.
export function ProfilConnected({ user, stats }: { user: UserModel; stats: ProfilStats }) {
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [confidentialiteOpen, setConfidentialiteOpen] = useState(false);
  const [aideOpen, setAideOpen] = useState(false);
  const [aboutOpen, setAboutOpen] = useState(false);

  return (
    <div className="pb-8">
      {/* Header */}
      <div className="rounded-b-[32px] bg-gradient-to-br from-mboa-primary-dark via-mboa-primary to-mboa-primary-light pb-6 pt-4">
        <div className="mx-auto flex max-w-2xl items-center justify-between px-5">
          <h1 className="text-xl font-extrabold text-white">Mon Profil</h1>
          <Link
            href="/profil/edit"
            aria-label="Modifier le profil"
            className="flex h-[38px] w-[38px] items-center justify-center rounded-xl bg-white/20 text-white"
          >
            <EditIcon className="h-[18px] w-[18px]" />
          </Link>
        </div>

        <div className="mx-auto mt-6 flex max-w-2xl flex-col items-center px-5 text-center">
          <span className="flex h-[84px] w-[84px] items-center justify-center rounded-full border-[3px] border-white/50 bg-white/20 text-[30px] font-extrabold text-white">
            {initiales(user.nom)}
          </span>
          <p className="mt-3 text-xl font-extrabold text-white">{user.nom}</p>
          <p className="mt-1 text-[13px] text-white/75">{user.email}</p>

          <div className="mt-2.5 flex flex-wrap items-center justify-center gap-2">
            {user.verified && (
              <span className="rounded-mboa-full bg-mboa-verified px-3 py-1 text-[11px] font-semibold text-white">
                ✅ Compte vérifié
              </span>
            )}
            <span className="rounded-mboa-full bg-white/30 px-3 py-1 text-[11px] font-semibold text-white">
              📅 Depuis {formatDateFr(user.dateInscription)}
            </span>
          </div>

          <div className="mt-6 flex w-full items-center justify-evenly rounded-2xl bg-white/15 py-4">
            <Stat value={stats.nbFavoris} label="Favoris" emoji="❤️" />
            <div className="h-10 w-px bg-white/20" />
            <Stat value={stats.nbAlertes} label="Alertes" emoji="🔔" />
            <div className="h-10 w-px bg-white/20" />
            <Stat value={stats.nbMessagesNonLus} label="Messages" emoji="💬" />
          </div>
        </div>
      </div>

      <div className="mx-auto mt-4 flex max-w-2xl flex-col gap-3">
        <MenuSection title="Mes activités">
          <MenuItem
            icon={<HeartIcon />}
            iconColorClass="text-mboa-danger"
            iconBgClass="bg-mboa-danger/12"
            label="Mes favoris"
            badge={stats.nbFavoris}
            href="/profil/favoris"
          />
          <MenuItem
            icon={<BellIcon />}
            iconColorClass="text-mboa-boost"
            iconBgClass="bg-mboa-boost/12"
            label="Mes alertes de recherche"
            badge={stats.nbAlertes}
            href="/profil/alertes"
          />
          <MenuItem
            icon={<ChatIcon />}
            iconColorClass="text-mboa-primary"
            iconBgClass="bg-mboa-primary/12"
            label="Mes messages"
            badge={stats.nbMessagesNonLus}
            href="/chat"
          />
          {user.role === "vendeur" && (
            <MenuItem
              icon={<StarIcon />}
              iconColorClass="text-mboa-boost"
              iconBgClass="bg-mboa-boost/12"
              label="Avis à modérer"
              badge={stats.nbAvisEnAttente}
              href="/profil/avis-moderation"
            />
          )}
        </MenuSection>

        <MenuSection title="Mon compte">
          <MenuItem
            icon={<PersonIcon />}
            iconColorClass="text-mboa-primary"
            iconBgClass="bg-mboa-primary/12"
            label="Modifier mon profil"
            href="/profil/edit"
          />
          <MenuItem
            icon={<PhoneIcon />}
            iconColorClass="text-mboa-primary-light"
            iconBgClass="bg-mboa-primary-light/12"
            label="Mon WhatsApp"
            subtitle={user.telephone ?? "Non renseigné"}
            href="/profil/edit"
          />
          <MenuItem
            icon={<LockIcon />}
            iconColorClass="text-mboa-text-muted"
            iconBgClass="bg-mboa-text-muted/12"
            label="Changer le mot de passe"
            onClick={() => setPasswordOpen(true)}
          />
          {user.role === "visiteur" && (
            <MenuItem
              icon={<StorefrontIcon />}
              iconColorClass="text-mboa-secondary"
              iconBgClass="bg-mboa-secondary/12"
              label="Devenir contributeur"
              subtitle="Publier des logements ou articles"
              href="/profil/devenir-contributeur"
            />
          )}
          {user.role === "vendeur" && (
            <MenuItem
              icon={<AddBusinessIcon />}
              iconColorClass="text-mboa-secondary"
              iconBgClass="bg-mboa-secondary/12"
              label="Étendre mes activités"
              subtitle="Ajouter logements et/ou articles"
              href="/profil/devenir-contributeur?dejaVendeur=1"
            />
          )}
        </MenuSection>

        <MenuSection title="Paramètres">
          <MenuItem
            icon={<BellIcon />}
            iconColorClass="text-mboa-secondary"
            iconBgClass="bg-mboa-secondary/12"
            label="Notifications"
            trailing={<NotificationToggle />}
          />
          <MenuItem
            icon={<ShieldIcon />}
            iconColorClass="text-mboa-primary"
            iconBgClass="bg-mboa-primary/12"
            label="Confidentialité"
            onClick={() => setConfidentialiteOpen(true)}
          />
          <MenuItem
            icon={<HelpIcon />}
            iconColorClass="text-mboa-primary-light"
            iconBgClass="bg-mboa-primary-light/12"
            label="Aide & Support"
            onClick={() => setAideOpen(true)}
          />
          <MenuItem
            icon={<InfoIcon />}
            iconColorClass="text-mboa-text-muted"
            iconBgClass="bg-mboa-text-muted/12"
            label="À propos de Mboa"
            subtitle="Version 1.0.0"
            onClick={() => setAboutOpen(true)}
          />
        </MenuSection>

        <div className="mx-5 flex items-center gap-3 rounded-mboa-lg border border-mboa-primary/15 bg-mboa-primary/6 p-3.5">
          <span className="text-xl" aria-hidden>
            👤
          </span>
          <div>
            <p className="text-[11px] text-mboa-text-muted">Type de compte</p>
            <p className="text-[13px] font-bold text-mboa-primary">
              {ROLE_LABELS[user.role] ?? ROLE_LABELS.visiteur}
            </p>
          </div>
        </div>

        <div className="mx-5">
          <LogoutButton variant="card" />
        </div>
      </div>

      <ChangePasswordDialog open={passwordOpen} onClose={() => setPasswordOpen(false)} />
      <InfoDialog
        open={confidentialiteOpen}
        onClose={() => setConfidentialiteOpen(false)}
        title="🛡 Confidentialité"
        body="Mboa protège tes données personnelles : ton numéro WhatsApp et ton email ne sont visibles que par les vendeurs/propriétaires avec qui tu échanges via le chat de l'application. Aucune donnée n'est partagée avec des tiers."
        closeLabel="Compris"
      />
      <InfoDialog
        open={aideOpen}
        onClose={() => setAideOpen(false)}
        title="💬 Aide & Support"
        body="Une question ou un problème avec ton compte, une annonce ou un paiement ? Contacte l'équipe Mboa via le chat de l'application ou par WhatsApp au support Mboa."
      />
      <AboutDialog open={aboutOpen} onClose={() => setAboutOpen(false)} />
    </div>
  );
}

function Stat({ value, label, emoji }: { value: number; label: string; emoji: string }) {
  return (
    <div className="flex flex-col items-center">
      <span className="text-xl">{emoji}</span>
      <span className="mt-1 text-lg font-extrabold text-white">{value}</span>
      <span className="text-[11px] text-white/75">{label}</span>
    </div>
  );
}
