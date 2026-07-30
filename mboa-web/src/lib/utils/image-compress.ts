// Miroir du redimensionnement fait par image_picker côté mobile
// (publier_screen.dart : maxWidth 1200, maxHeight 1200, imageQuality 80) —
// le web n'avait aucune étape équivalente, laissant passer des photos de
// téléphone non compressées (plusieurs Mo) directement vers Supabase
// Storage. Au-delà de l'espace de stockage gaspillé, une photo trop lourde
// pouvait faire planter la modération IA côté serveur (moderate-annonce
// charge l'image entière en mémoire pour son hash anti-fraude) et bloquer
// l'annonce indéfiniment.
const MAX_DIMENSION = 1200;
const JPEG_QUALITY = 0.8;

// En cas d'échec de décodage (format exotique, fichier corrompu...), on
// renvoie le fichier original plutôt que de bloquer la publication : mieux
// vaut une photo non compressée qu'une photo manquante.
export async function compresserImage(file: File): Promise<File> {
  if (!file.type.startsWith("image/")) return file;

  try {
    const bitmap = await createImageBitmap(file);
    const ratio = Math.min(1, MAX_DIMENSION / Math.max(bitmap.width, bitmap.height));
    const width = Math.round(bitmap.width * ratio);
    const height = Math.round(bitmap.height * ratio);

    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    if (!ctx) return file;
    ctx.drawImage(bitmap, 0, 0, width, height);
    bitmap.close();

    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, "image/jpeg", JPEG_QUALITY),
    );
    if (!blob) return file;

    // Une image déjà petite/bien compressée peut ressortir plus lourde
    // après ré-encodage JPEG (ex. PNG avec transparence) : on garde alors
    // l'original plutôt que de dégrader inutilement.
    if (blob.size >= file.size) return file;

    const nomJpeg = file.name.replace(/\.[^.]+$/, "") + ".jpg";
    return new File([blob], nomJpeg, { type: "image/jpeg" });
  } catch (e) {
    console.error("compresserImage a échoué, envoi du fichier original:", e);
    return file;
  }
}
