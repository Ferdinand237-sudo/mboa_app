import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-4 text-center">
      <span className="text-4xl" aria-hidden>
        🧭
      </span>
      <h1 className="mt-4 text-xl font-extrabold text-mboa-text">
        Page introuvable
      </h1>
      <p className="mt-2 text-sm text-mboa-text-muted">
        Cette annonce ou cette page n&apos;existe pas ou plus.
      </p>
      <Link
        href="/"
        className="mt-6 rounded-mboa-lg bg-mboa-primary px-6 py-3 text-sm font-bold text-white"
      >
        Retour à l&apos;accueil
      </Link>
    </div>
  );
}
