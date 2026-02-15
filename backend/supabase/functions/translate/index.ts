import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "https://esm.sh/openai@4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { text } = await req.json();
    if (!text || typeof text !== "string" || text.length > 1000) {
      return new Response(
        JSON.stringify({ error: "Invalid input. Provide 1-1000 characters." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese-English dictionary assistant. Given an English word or phrase, return a JSON object with:
- "english": the original English input
- "chinese": natural, conversational Chinese translation
- "pinyin": pinyin with tone marks (not numbers)
- "meaning": a concise English definition/explanation
- "notes": usage notes or context (1-2 sentences)
- "examples": array of 1-2 example sentences, each with "zh" (Chinese), "pinyin", and "en" (English)
- "tags_suggested": array of 1-3 category tags (e.g. "tech", "daily", "formal", "food")
- "segments": array of objects, one per Chinese character, each with "char" and "py" (pinyin syllable with tone mark)

Always use tone marks in pinyin (e.g. māmā, not ma1ma1). Prefer natural, conversational Chinese.`,
        },
        {
          role: "user",
          content: text,
        },
      ],
    });

    const result = JSON.parse(completion.choices[0].message.content!);

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
