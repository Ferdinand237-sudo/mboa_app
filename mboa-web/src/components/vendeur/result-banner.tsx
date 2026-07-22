import type { ToneResultat } from "@/lib/utils/moderation";

const TONE_CLASSES: Record<ToneResultat, string> = {
  success: "bg-mboa-primary/10 text-mboa-primary",
  warning: "bg-mboa-boost/10 text-mboa-boost",
  danger: "bg-mboa-danger/10 text-mboa-danger",
};

export function ResultBanner({ message, tone }: { message: string; tone: ToneResultat }) {
  return (
    <p className={`rounded-mboa-md px-4 py-3 text-sm font-semibold ${TONE_CLASSES[tone]}`}>{message}</p>
  );
}
