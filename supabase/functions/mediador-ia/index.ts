import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function callGemini(
  prompt: string,
  expectJson: boolean,
): Promise<string> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY_NOT_CONFIGURED");
  }

  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const body: Record<string, unknown> = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.45,
      maxOutputTokens: 700,
      ...(expectJson ? { responseMimeType: "application/json" } : {}),
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`GEMINI_HTTP_${resp.status}: ${errText}`);
  }

  const data = await resp.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== "string" || text.trim().length === 0) {
    throw new Error("GEMINI_EMPTY_RESPONSE");
  }
  return text.trim();
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Método no permitido" }, 405);
  }

  try {
    const body = await req.json();
    const modo = String(body?.modo ?? "consulta_mediador");
    const reglamentoTexto = String(body?.reglamentoTexto ?? "");

    if (modo === "mejorar_argumento") {
      const categoria = String(body?.categoria ?? "Otros");
      const propuesta = String(body?.propuesta ?? "");
      const borradorArgumento = String(body?.borradorArgumento ?? "");
      const interesPropio = String(body?.interesPropio ?? "");
      const interesContraparte = String(body?.interesContraparte ?? "");

      const prompt = `
Eres un mediador experto en el Método Harvard de negociación y narrativa persuasiva constructiva para conflictos vecinales.
Tu tarea es mejorar el argumento de una propuesta sin atacar a la persona, enfocándote en intereses mutuos y en el reglamento vigente del condominio.

Categoría del conflicto: ${categoria}
Propuesta concreta: ${propuesta}
Borrador actual del vecino: ${borradorArgumento}
Interés real de quien propone: ${interesPropio || "No especificado"}
Interés real de la contraparte: ${interesContraparte || "No especificado"}

${reglamentoTexto}

Devuelve exclusivamente un JSON válido con esta estructura exacta:
{
  "argumentoMejorado": "Texto en español neutral, empático y firme (entre 25 y 65 palabras) listo para colocar en el campo Argumento persuasivo.",
  "criterioSugerido": "La etiqueta exacta del artículo del reglamento listado arriba que mejor respalda la propuesta.",
  "explicacionBreve": "Una frase corta explicando por qué funciona mejor según el Método Harvard."
}
`.trim();

      const raw = await callGemini(prompt, true);
      const parsed = JSON.parse(raw);
      return jsonResponse({
        argumentoMejorado: String(parsed?.argumentoMejorado ?? "").trim(),
        criterioSugerido: String(parsed?.criterioSugerido ?? "").trim(),
        explicacionBreve: String(parsed?.explicacionBreve ?? "").trim(),
      });
    }

    const consultaUsuario = String(body?.consultaUsuario ?? "");
    const rolActivo = String(body?.rolActivo ?? "Vecino");
    const negociacion = body?.negociacion ?? {};
    const historial = Array.isArray(body?.historial) ? body.historial : [];

    const historialReciente = historial
      .slice(-6)
      .map((m: Record<string, unknown>) =>
        `${m?.esUsuario ? "Vecino" : "Mediador"}: ${m?.texto ?? ""}`
      )
      .join("\n");

    const prompt = `
Eres el Mediador IA imparcial de AcuerdoVecinal. Ayudas a vecinos de un condominio a resolver conflictos aplicando estrictamente:
1. Separar a las personas del problema (lenguaje respetuoso, nunca acusatorio).
2. Concentrarse en los intereses reales y no en posiciones rígidas.
3. Buscar opciones de beneficio mutuo.
4. Respaldar propuestas en criterios objetivos del Reglamento Interno del condominio.

Usuario que consulta: ${rolActivo}
Caso: "${negociacion?.titulo ?? ""}" (Categoría: ${negociacion?.categoria ?? ""})
Descripción: ${negociacion?.descripcionProblema ?? ""}
Interés solicitante (${negociacion?.dptoSolicitante ?? ""}): ${negociacion?.interesSolicitante ?? "Pendiente"}
Interés receptor (${negociacion?.dptoReceptor ?? ""}): ${negociacion?.interesReceptor ?? "Pendiente"}
Cláusulas actuales: ${JSON.stringify(negociacion?.condiciones ?? [])}

${reglamentoTexto}

Historial reciente de consulta:
${historialReciente || "Sin mensajes previos."}

Consulta actual del vecino:
"${consultaUsuario}"

Responde en español claro y práctico (máximo 140 palabras), incluyendo 1 o 2 sugerencias accionables y citando el artículo del reglamento si aplica.
`.trim();

    const respuesta = await callGemini(prompt, false);
    return jsonResponse({ respuesta });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    const status = message.includes("GEMINI_API_KEY_NOT_CONFIGURED")
      ? 503
      : 500;
    return jsonResponse({ error: message }, status);
  }
});
