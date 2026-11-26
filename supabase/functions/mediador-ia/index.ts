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

function cleanJsonFences(raw: string): string {
  return raw
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();
}

async function callGeminiWithModel(
  apiKey: string,
  model: string,
  prompt: string,
  expectJson: boolean,
): Promise<{ ok: boolean; status: number; text?: string; errText?: string }> {
  const cleanModel = model.replace(/^models\//, "");
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${cleanModel}:generateContent?key=${apiKey}`;

  const body: Record<string, unknown> = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 1200,
      ...(expectJson ? { responseMimeType: "application/json" } : {}),
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    return {
      ok: false,
      status: resp.status,
      errText: await resp.text(),
    };
  }

  const data = await resp.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== "string" || text.trim().length === 0) {
    return {
      ok: false,
      status: 502,
      errText: "GEMINI_EMPTY_RESPONSE",
    };
  }
  return { ok: true, status: 200, text: text.trim() };
}

async function callGemini(
  prompt: string,
  expectJson: boolean,
): Promise<string> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY_NOT_CONFIGURED");
  }

  const envModel = Deno.env.get("GEMINI_MODEL")?.trim();
  const candidates = Array.from(
    new Set(
      [
        ...(envModel ? [envModel] : []),
        "gemini-3.8-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash",
      ].filter((m) => m.length > 0),
    ),
  );

  let lastError = "GEMINI_UNAVAILABLE";
  for (const model of candidates) {
    const res = await callGeminiWithModel(apiKey, model, prompt, expectJson);
    if (res.ok && res.text) {
      return expectJson ? cleanJsonFences(res.text) : res.text;
    }
    lastError = `GEMINI_HTTP_${res.status} (${model}): ${res.errText ?? ""}`;
    // Only retry another model when current model ID is not found/deprecated (404).
    if (res.status !== 404) {
      break;
    }
  }

  throw new Error(lastError);
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

    if (modo === "estructurar_caso") {
      const relatoUsuario = String(body?.relatoUsuario ?? "");
      const categorias = Array.isArray(body?.categorias)
        ? body.categorias.join(", ")
        : "Ruido, Mascotas, Cochera, Áreas Comunes, Otros";

      const prompt = `
Eres un mediador experto en el Método Harvard de negociación vecinal.
El vecino describió su problema cotidiano en lenguaje informal:
"${relatoUsuario}"

Categorías permitidas (elige exactamente UNA): ${categorias}

${reglamentoTexto}

Convierte este relato en una solicitud constructiva (separando persona y problema, sin ataques, centrada en intereses reales y respaldo normativo).
Devuelve exclusivamente un JSON válido con esta estructura exacta:
{
  "titulo": "Título breve y neutral (6 a 45 caracteres)",
  "categoria": "Una sola categoría de la lista permitida",
  "descripcionProblema": "Descripción objetiva de los hechos concretos (mín. 20 caracteres)",
  "interesSolicitante": "Necesidad real que protege el vecino (descanso, seguridad, acceso, etc., mín. 15 caracteres)",
  "tituloClausula": "Título corto de la primera cláusula propuesta (mín. 8 caracteres)",
  "descripcionPropuesta": "Medida concreta, medible y razonable (mín. 20 caracteres)",
  "criterioObjetivo": "La etiqueta exacta de uno de los artículos del reglamento listado arriba",
  "argumentoPersuasivo": "Argumento empático de beneficio mutuo (25 a 65 palabras)"
}
`.trim();

      const raw = await callGemini(prompt, true);
      const parsed = JSON.parse(raw);
      return jsonResponse({
        titulo: String(parsed?.titulo ?? "").trim(),
        categoria: String(parsed?.categoria ?? "Otros").trim(),
        descripcionProblema: String(parsed?.descripcionProblema ?? "").trim(),
        interesSolicitante: String(parsed?.interesSolicitante ?? "").trim(),
        tituloClausula: String(parsed?.tituloClausula ?? "").trim(),
        descripcionPropuesta: String(parsed?.descripcionPropuesta ?? "").trim(),
        criterioObjetivo: String(parsed?.criterioObjetivo ?? "").trim(),
        argumentoPersuasivo: String(parsed?.argumentoPersuasivo ?? "").trim(),
      });
    }

    if (modo === "sugerir_contrapropuesta") {
      const tituloClausula = String(body?.tituloClausula ?? "");
      const propuestaActual = String(body?.propuestaActual ?? "");
      const motivoRechazo = String(body?.motivoRechazo ?? "");
      const categoria = String(body?.categoria ?? "Otros");
      const interesPropio = String(body?.interesPropio ?? "");
      const interesContraparte = String(body?.interesContraparte ?? "");

      const prompt = `
Eres un mediador experto en el Método Harvard buscando una solución puente de beneficio mutuo.
Cláusula en debate: "${tituloClausula}" (Categoría: ${categoria})
Propuesta actual en mesa: "${propuestaActual}"
Motivo de rechazo o reparo previo: "${motivoRechazo || "No especificado"}"
Interés de quien contraoferta: "${interesPropio || "No especificado"}"
Interés de la otra parte: "${interesContraparte || "No especificado"}"

${reglamentoTexto}

Formula una contrapropuesta equilibrada de punto medio.
Devuelve exclusivamente un JSON válido con esta estructura exacta:
{
  "nuevaPropuesta": "Propuesta concreta y verificable de punto medio (20 a 55 palabras)",
  "criterioSugerido": "La etiqueta exacta del artículo del reglamento listado arriba que mejor respalda la alternativa",
  "argumentoMejorado": "Sustento empático explicando cómo atiende ambos intereses (25 a 65 palabras)",
  "explicacionBreve": "Frase corta explicando el punto de equilibrio alcanzado."
}
`.trim();

      const raw = await callGemini(prompt, true);
      const parsed = JSON.parse(raw);
      return jsonResponse({
        nuevaPropuesta: String(parsed?.nuevaPropuesta ?? "").trim(),
        criterioSugerido: String(parsed?.criterioSugerido ?? "").trim(),
        argumentoMejorado: String(parsed?.argumentoMejorado ?? "").trim(),
        explicacionBreve: String(parsed?.explicacionBreve ?? "").trim(),
      });
    }

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
