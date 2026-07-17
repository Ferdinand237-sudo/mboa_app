// Seul point d'accès en lecture aux attestations du bucket privé
// attestations-proprietaires. Vérifie que l'appelant est admin ou
// l'ambassadeur assigné à la vérification, génère une URL signée de
// courte durée, et journalise l'accès dans attestations_acces_log
// (qui consulte, quand) — c'est ce mécanisme, et non une policy RLS
// storage, qui remplit l'exigence d'audit du cahier des charges.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SIGNED_URL_TTL_SECONDS = 300

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Non authentifié' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const callerToken = authHeader.replace('Bearer ', '')
    const { data: callerData, error: callerError } = await supabaseAdmin.auth.getUser(callerToken)
    if (callerError || !callerData.user) {
      return new Response(
        JSON.stringify({ error: 'Non authentifié' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    const callerId = callerData.user.id

    const { verificationId } = await req.json()
    if (!verificationId) {
      return new Response(
        JSON.stringify({ error: 'verificationId requis' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: verification, error: verifError } = await supabaseAdmin
      .from('verifications_terrain')
      .select('id, ambassadeur_id, attestation_path')
      .eq('id', verificationId)
      .single()

    if (verifError || !verification) {
      return new Response(
        JSON.stringify({ error: 'Vérification introuvable' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!verification.attestation_path) {
      return new Response(
        JSON.stringify({ error: 'Aucune attestation associée' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: callerProfile } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', callerId)
      .single()

    const estAdmin = callerProfile?.role === 'admin'
    const estAmbassadeurAssigne = verification.ambassadeur_id === callerId

    if (!estAdmin && !estAmbassadeurAssigne) {
      return new Response(
        JSON.stringify({ error: "Accès réservé à l'administration ou à l'ambassadeur assigné" }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: signed, error: signedError } = await supabaseAdmin.storage
      .from('attestations-proprietaires')
      .createSignedUrl(verification.attestation_path, SIGNED_URL_TTL_SECONDS)

    if (signedError || !signed) {
      return new Response(
        JSON.stringify({ error: signedError?.message ?? 'Impossible de générer le lien' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    await supabaseAdmin.from('attestations_acces_log').insert({
      verification_id: verificationId,
      consulte_par: callerId,
    })

    return new Response(
      JSON.stringify({ url: signed.signedUrl }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
