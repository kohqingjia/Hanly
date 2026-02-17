import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "https://esm.sh/openai@4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
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

    const { context_summary, context_tags, chinese_level } = await req.json();

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const tagsList = (context_tags || []).join(", ");

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a Chinese vocabulary recommender for language learners.
User profile: ${context_summary || "General learner"}
Focus areas: ${tagsList || "general"}
Chinese level: ${chinese_level || "beginner"}

Generate exactly 18 starter vocabulary words appropriate for this learner's level and interests.

Return a JSON object with a "words" array. Each word object has:
- "english": English word/phrase
- "chinese": simplified Chinese
- "pinyin": pinyin with tone marks (e.g. māmā, not ma1ma1)
- "meaning": concise English definition
- "examples": array with exactly 1 example sentence, each with "zh" (Chinese), "pinyin", "en" (English)
- "tags_suggested": 1-2 tags from ONLY these categories: daily, work, travel, food, academic, formal, casual, culture
- "segments": array of objects, one per Chinese character, each with "char" and "py" (pinyin syllable with tone mark)

Mix practical everyday words with words relevant to the user's specific interests.
Order from simpler to more advanced.
Always use tone marks in pinyin.`,
        },
        {
          role: "user",
          content: "Generate starter vocabulary for me.",
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
