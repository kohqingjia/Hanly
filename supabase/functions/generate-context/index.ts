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

    const { chinese_level, learning_purposes, industry, additional_context } =
      await req.json();

    const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });

    const userProfile = [
      `Chinese level: ${chinese_level || "not specified"}`,
      `Learning purposes: ${(learning_purposes || []).join(", ") || "general"}`,
      industry ? `Industry: ${industry}` : null,
      additional_context ? `Additional context: ${additional_context}` : null,
    ]
      .filter(Boolean)
      .join("\n");

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: `You are a language learning profile analyzer. Given a user's learning profile, generate:
1. "context_summary": A 1-2 sentence summary of who this learner is and what they need (e.g. "Intermediate learner working in tech, focused on professional communication and daily conversation.")
2. "context_tags": An array of 3-8 flat tags that capture their level, purposes, industry, and any keywords from their additional context. Tags should be lowercase, single words or short phrases. Examples: "intermediate", "tech", "business", "travel", "hsk4", "software-engineering", "daily-conversation"

Return a JSON object with these two fields only.`,
        },
        {
          role: "user",
          content: userProfile,
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
